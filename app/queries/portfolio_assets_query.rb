class PortfolioAssetsQuery
  attr_reader :user

  def initialize(user, options = {})
    @user = user
  end

  def call
    grouped_assets = user.assets
      .includes(:transactions)
      .group_by(&:symbol)

    # Get all unique symbols for batch price fetch
    symbols = grouped_assets.keys
    
    # Fetch all prices at once
    prices = CryptoApi.get_prices(symbols)

    result = {}

    grouped_assets.each do |symbol, assets|
      total_quantity = 0
      total_value = 0
      purchase_price = 0
      current_price = prices[symbol]
      
      # Skip if no price available
      next unless current_price

      assets.each do |asset|
        total_quantity += asset.quantity
        
        # Skip assets with zero quantity
        next if asset.quantity.zero?
        
        asset_value = asset.quantity * current_price
        total_value += asset_value
        
        # Calculate weighted contribution to purchase price
        purchase_price += (asset.purchase_price * asset.quantity)
      end

      # Skip if no assets or all have zero quantity
      next if total_quantity.zero?

      # Calculate the weighted average purchase price
      avg_purchase_price = purchase_price / total_quantity
      
      # Calculate profit/loss
      profit_loss = ((current_price - avg_purchase_price) / avg_purchase_price) * 100
      
      result[symbol] = {
        symbol: symbol,
        name: assets.first.name,
        total_quantity: total_quantity,
        avg_purchase_price: avg_purchase_price,
        current_price: current_price,
        total_value: total_value,
        profit_loss: profit_loss
      }
    end

    result
  end

  def total_portfolio_value
    call.values.sum { |asset| asset[:total_value] }
  end

  def get_asset(symbol)
    # For a single asset, we can optimize by not fetching all prices
    assets = user.assets.where(symbol: symbol)
    return {} if assets.empty?
    
    total_quantity = assets.sum(:quantity)
    return {} if total_quantity.zero?
    
    # Get current price
    current_price = CryptoApi.get_price(symbol)
    
    return {} unless current_price
    
    # Calculate weighted average purchase price
    purchase_price = assets.sum { |asset| asset.purchase_price * asset.quantity } / total_quantity
    
    # Calculate total value and profit/loss
    total_value = total_quantity * current_price
    profit_loss = ((current_price - purchase_price) / purchase_price) * 100
    
    {
      symbol: symbol,
      name: assets.first.name,
      total_quantity: total_quantity,
      avg_purchase_price: purchase_price,
      current_price: current_price,
      total_value: total_value,
      profit_loss: profit_loss
    }
  end
end 