class TransactionCreator
  def self.create_buy(user, asset_data, quantity, price)
    # Find existing asset or create a new one
    asset = user.assets.find_by(symbol: asset_data[:symbol])

    if asset
      # Calculate new weighted average purchase price
      total_value_before = asset.quantity * (asset.purchase_price || 0)
      new_value = quantity * price
      total_quantity = asset.quantity + quantity
      weighted_avg_price = (total_value_before + new_value) / total_quantity

      # Update existing asset
      unless asset.update(
        quantity: total_quantity,
        purchase_price: weighted_avg_price
      )
        return { success: false, errors: asset.errors.full_messages, asset: asset }
      end
    else
      # Create a new asset record
      asset = user.assets.build(
        symbol: asset_data[:symbol],
        name: asset_data[:name],
        quantity: quantity,
        purchase_price: price
      )
      
      unless asset.save
        return { success: false, errors: asset.errors.full_messages, asset: asset }
      end
    end

    # Create a transaction record
    transaction = Transaction.new(
      user_id: user.id,
      asset_id: asset.id,
      transaction_type: Transaction::TYPES[:buy],
      quantity: quantity,
      price: price
    )

    if transaction.save
      { success: true, asset: asset, transaction: transaction }
    else
      asset.destroy if asset.transactions.count == 0
      { success: false, errors: transaction.errors.full_messages, asset: asset }
    end
  end
  
  def self.create_sell(user, asset_symbol, quantity_to_sell, price)
    # Find assets with this symbol
    assets = user.assets.where(symbol: asset_symbol).order(created_at: :asc)
    total_available = assets.sum(:quantity)
    
    if quantity_to_sell > total_available
      return { 
        success: false, 
        errors: ["Cannot sell more than you own (#{total_available} available)"]
      }
    end
    
    # Process the sell transaction using FIFO method (First In, First Out)
    remaining_to_sell = quantity_to_sell
    processed_assets = []
    transactions = []

    assets.each do |asset|
      break if remaining_to_sell <= 0
      
      if asset.quantity <= remaining_to_sell
        # Sell the entire asset
        sell_quantity = asset.quantity
        remaining_to_sell -= sell_quantity
        
        # Create a sell transaction
        transaction = Transaction.create(
          user_id: user.id,
          asset_id: asset.id,
          transaction_type: Transaction::TYPES[:sell],
          quantity: sell_quantity,
          price: price
        )
        
        # Update the asset quantity to zero
        asset.update(quantity: 0)
        
        processed_assets << asset.id
        transactions << transaction
      else
        # Sell part of the asset
        sell_quantity = remaining_to_sell
        new_quantity = asset.quantity - sell_quantity
        
        # Create a sell transaction
        transaction = Transaction.create(
          user_id: user.id,
          asset_id: asset.id,
          transaction_type: Transaction::TYPES[:sell],
          quantity: sell_quantity,
          price: price
        )

        # Update the asset with the new quantity
        asset.update(quantity: new_quantity)

        processed_assets << asset.id
        transactions << transaction
        remaining_to_sell = 0
      end
    end
    
    { 
      success: true,
      quantity_sold: quantity_to_sell,
      assets: processed_assets,
      transactions: transactions
    }
  end
end 