class PortfolioController < ApplicationController
  include AssetCalculator

  before_action :authenticate_user!
  before_action :set_page_title
  protect_from_forgery with: :exception, reset_session: true

  def index
    # Get portfolio assets using the query object
    portfolio_query = PortfolioAssetsQuery.new(current_user)
    @portfolio_assets = portfolio_query.call

    # Convert to an array and sort by total value descending
    @portfolio_assets = @portfolio_assets.values.sort_by { |asset| -asset[:total_value] }

    # Calculate total portfolio value
    @total_value = portfolio_query.total_portfolio_value
  end

  def new
    @asset = current_user.assets.build

    # load coins from database or fetch from API
    @cryptocurrencies = Coin.any? ? Coin.all.order(:id) : CryptocurrencyService.fetch_top_cryptocurrencie
  end

  def create
    # Use the transaction creator query for initial asset creation
    creator = TransactionCreatorQuery.new(current_user, params)
    result = creator.create_buy

    if result[:success]
      redirect_to portfolio_path
    else
      @asset = result[:asset] || current_user.assets.build
      @cryptocurrencies = CryptocurrencyService.fetch_top_cryptocurrencies
      flash.now[:alert] = result[:errors].join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def transactions
    symbol = params[:symbol]
    @transactions_query = TransactionsQuery.new(current_user)
    @transactions = [] # Initialize with empty array by default

    # Get all transactions for this asset
    if symbol.present?
      @asset = Asset.find_by(symbol: symbol)
      
      # If asset is found, get its transactions
      if @asset.present?
        @transactions = Transaction.where(asset: @asset, user: current_user).order(created_at: :desc)
        
        # Get asset details through PortfolioAssetsQuery for profit/loss calculation
        @asset_details = PortfolioAssetsQuery.new(current_user).get_asset(symbol)
        
        # If no asset details, create minimal details
        if @asset_details.blank?
          current_price = CryptoApi.get_price(symbol)
          @asset_details = {
            name: @asset.name,
            total_quantity: @asset.quantity,
            current_price: current_price,
            total_value: @asset.quantity * current_price,
            profit_loss: 0 # Default when we can't calculate
          }
        end
        
        @asset_symbol = symbol
      end
    else
      # Get all transactions with optional filters
      options = {}
      options[:transaction_type] = params[:type].to_i if params[:type].present?
      options[:start_date] = params[:start_date] if params[:start_date].present?
      options[:end_date] = params[:end_date] if params[:end_date].present?
      options[:sort] = params[:sort] || "desc"

      @transactions = @transactions_query.all_transactions(options)
      @grouped_by_asset = @transactions_query.grouped_by_asset
      @grouped_by_month = @transactions_query.grouped_by_month
      @total_buy_value = @transactions_query.total_buy_value
      @total_sell_value = @transactions_query.total_sell_value
      @realized_pl = @transactions_query.realized_profit_loss
    end
  end

  def add_more
    @asset_symbol = params[:symbol]

    # Get cryptocurrency details
    crypto_details = fetch_cryptocurrency_details(@asset_symbol)

    # Pre-select the cryptocurrency
    @asset = current_user.assets.build(symbol: @asset_symbol)
    @asset.name = crypto_details[:name] || @asset_symbol
    @current_price = crypto_details[:current_price] || 0
  end

  def add_transaction
    @asset_symbol = params[:asset][:symbol]

    # Use the transaction creator query
    creator = TransactionCreatorQuery.new(current_user, params)
    result = creator.create_buy

    if result[:success]
      redirect_to portfolio_transactions_path(symbol: @asset_symbol)
    else
      redirect_to add_more_portfolio_path(symbol: @asset_symbol)
    end
  end

  def sell
    @asset_symbol = params[:symbol]

    # Get asset details using our query
    transactions_query = AssetTransactionsQuery.new(current_user, @asset_symbol)
    @total_quantity = transactions_query.total_quantity
    @asset_details = transactions_query.asset_details

    # Get current price for the form
    crypto_details = fetch_cryptocurrency_details(@asset_symbol)
    @asset_name = @asset_details[:name] || crypto_details[:name]
    @current_price = @asset_details[:current_price] || crypto_details[:current_price] || 0

    @transaction = Transaction.new(transaction_type: "sell")
  end

  def create_sell
    @asset_symbol = params[:symbol]
    result = TransactionCreatorQuery.new(current_user, params).create_sell
    
    if result[:success]
      redirect_to portfolio_path
    else
      @error_message = result[:errors].join(", ")
      render :sell
    end
  end

  def edit_transaction
    @transaction = current_user.transactions.find(params[:id])
    @asset = @transaction.asset
    @asset_symbol = @asset.symbol

    # Get current price for reference
    crypto_details = fetch_cryptocurrency_details(@asset_symbol)
    @current_price = crypto_details[:current_price] || @asset.current_price || 0

    # For sell transactions, calculate the maximum available quantity
    if @transaction.transaction_type == "sell"
      @max_quantity = @transaction.quantity # Can't increase beyond original quantity for sells
    else
      @max_quantity = nil # No limit for buy transactions
    end
  end

  def update_transaction
    transaction = current_user.transactions.find(params[:id])
    original_quantity = transaction.quantity
    asset = transaction.asset

    new_quantity = params[:transaction][:quantity].to_f
    new_price = params[:transaction][:price].to_f

    if new_quantity <= 0 || new_price <= 0
      flash[:alert] = "Quantity and price must be greater than zero"
      redirect_to edit_transaction_portfolio_path(transaction)
      return
    end

    # For sell transactions, ensure we don't exceed available quantity
    if transaction.transaction_type == 'sell' && new_quantity > original_quantity
      flash[:alert] = "You cannot increase the quantity of a sell transaction"
      redirect_to edit_transaction_portfolio_path(transaction)
      return
    end

    # Update the asset quantity based on the transaction change
    if transaction.transaction_type == 'buy'
      # For buy transactions, adjust the asset quantity by the difference
      quantity_diff = new_quantity - original_quantity
      new_asset_quantity = asset.quantity + quantity_diff

      if new_asset_quantity < 0
        flash[:alert] = "Cannot reduce buy quantity as it would result in negative asset quantity"
        redirect_to edit_transaction_portfolio_path(transaction)
        return
      end

      asset.update(quantity: new_asset_quantity)
    else # sell transaction
      # For sell transactions, adjust the asset quantity by the inverse difference
      quantity_diff = original_quantity - new_quantity
      new_asset_quantity = asset.quantity + quantity_diff
      asset.update(quantity: new_asset_quantity)
    end

    # Update the transaction
    if transaction.update(quantity: new_quantity, price: new_price)
      redirect_to portfolio_transactions_path(symbol: asset.symbol)
    else
      # If update fails, restore the asset quantity
      asset.update(quantity: asset.quantity - quantity_diff)
      redirect_to edit_transaction_portfolio_path(transaction)
    end
  end

  def delete_transaction
    @transaction = current_user.transactions.find(params[:id])
    @asset = @transaction.asset
    @asset_symbol = @asset.symbol

    transaction_type = @transaction.transaction_type
    quantity = @transaction.quantity

    begin
      if transaction_type == "buy"
        new_quantity = quantity > @asset.quantity ? 0 : @asset.quantity - quantity
        @asset.update!(quantity: new_quantity)
      elsif transaction_type == "sell"
        @asset.update!(quantity: @asset.quantity + quantity)
      end

      @transaction.destroy!

      redirect_to portfolio_transactions_path(symbol: @asset_symbol)
    rescue => e
      redirect_to portfolio_transactions_path(symbol: @asset_symbol)
    end
  end

  private

  def set_page_title
    symbol = params[:symbol]

    @page_title = case action_name
    when "index"
      "My Portfolio"
    when "new"
      "Add Asset"
    when "transactions"
      "Transactions"
    when "add_more"
      "Buy #{symbol}"
    when "sell"
      "Sell #{symbol}"
    when "edit_transaction"
      "Edit Transaction"
    end
  end

  def asset_params
    params.require(:asset).permit(:symbol, :name, :quantity, :initial_purchase_price)
  end

  def fetch_top_cryptocurrencies
    CryptocurrencyService.fetch_top_cryptocurrencies
  end

  def fetch_cryptocurrency_details(symbol)
    cryptocurrencies = CryptocurrencyService.fetch_top_cryptocurrencies
    @selected_crypto = cryptocurrencies.find { |c| c[:symbol] == symbol }

    if @selected_crypto.present?
      {
        name: @selected_crypto[:name],
        current_price: @selected_crypto[:current_price],
        price_change_24h: @selected_crypto[:price_change_24h]
      }
    else
      # Try to get from existing asset
      asset = current_user.assets.find_by(symbol: symbol)
      if asset
        {
          name: asset.name,
          current_price: asset.current_price,
          price_change_24h: nil
        }
      else
        { name: symbol, current_price: nil, price_change_24h: nil }
      end
    end
  end
end
