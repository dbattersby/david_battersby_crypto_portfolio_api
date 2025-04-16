class AssetTransactionsQuery
  attr_reader :user, :symbol

  def initialize(user, symbol)
    @user = user
    @symbol = symbol
  end

  def call
    # Find all assets with the given symbol
    asset_ids = user.assets.where(symbol: symbol).pluck(:id)
    
    # Return transactions for those assets
    Transaction.where(asset_id: asset_ids, user_id: user.id)
      .order(created_at: :desc)
      .includes(:asset)
  end
  
  def assets
    user.assets.where(symbol: symbol)
  end
  
  def asset_details
    PortfolioAssetsQuery.new(user).get_asset(symbol)
  end
  
  def total_quantity
    assets.sum(:quantity)
  end
end 