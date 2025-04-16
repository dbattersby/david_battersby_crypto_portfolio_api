class TransactionCreatorQuery
  attr_reader :user, :params

  def initialize(user, params)
    @user = user
    @params = params
  end

  def create_buy
    symbol = params[:asset][:symbol]
    name = params[:asset][:name]
    quantity = params[:asset][:quantity].to_f.round(2)
    price = params[:asset][:initial_purchase_price].to_f

    # Validate inputs
    return { success: false, errors: [ "Quantity must be greater than zero" ] } if quantity <= 0
    return { success: false, errors: [ "Price must be greater than zero" ] } if price <= 0

    asset_data = {
      symbol: symbol,
      name: name
    }

    # Use the transaction creator service
    TransactionCreator.create_buy(user, asset_data, quantity, price)
  end

  def create_sell
    symbol = params[:symbol]
    quantity = params[:transaction][:quantity].to_f.round(2)
    price = params[:transaction][:price].to_f

    # Validate inputs
    return { success: false, errors: [ "Quantity must be greater than zero" ] } if quantity <= 0
    return { success: false, errors: [ "Price must be greater than zero" ] } if price <= 0

    # Use the transaction creator service
    TransactionCreator.create_sell(user, symbol, quantity, price)
  end
end
