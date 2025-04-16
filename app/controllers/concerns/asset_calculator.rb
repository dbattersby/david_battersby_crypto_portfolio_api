module AssetCalculator
  extend ActiveSupport::Concern
  
  # Calculate weighted average purchase price
  def calculate_weighted_price(asset, new_quantity, new_price)
    return new_price if asset.nil? || asset.quantity.to_f.zero?
    
    total_value_before = asset.quantity * (asset.purchase_price || 0)
    new_value = new_quantity * new_price
    total_quantity = asset.quantity + new_quantity
    
    return new_price if total_quantity.zero?
    (total_value_before + new_value) / total_quantity
  end
  
  # Calculate total value of assets
  def calculate_total_value(assets)
    assets.sum { |asset| asset.current_value || 0 }
  end
  
  # Calculate profit/loss for a given asset
  def calculate_profit_loss(current_price, purchase_price)
    return 0 if purchase_price.to_f.zero? || current_price.nil?
    ((current_price - purchase_price.to_f) / purchase_price.to_f) * 100
  end
  
  # Group assets by symbol and combine quantities/values
  def group_assets_by_symbol(assets)
    assets.group_by(&:symbol).map do |symbol, assets_group|
      combined_asset = assets_group.first.dup
      total_quantity = assets_group.sum(&:quantity)

      # Calculate weighted average purchase price
      if total_quantity > 0
        combined_asset.weighted_purchase_price = assets_group.sum { |asset| asset.quantity * asset.purchase_price } / total_quantity
      end

      combined_asset.quantity = total_quantity
      combined_asset.transaction_count = assets_group.flat_map(&:transactions).count
      combined_asset
    end
  end
end 