class Transaction < ApplicationRecord
  TYPES = { buy: "buy", sell: "sell" }.freeze
  
  belongs_to :user
  belongs_to :asset

  validates :transaction_type, presence: true, inclusion: { in: TYPES.values }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_create :update_asset_quantity

  private

  def update_asset_quantity
    # Skip if this is the first transaction for the asset
    return if is_first_transaction?

    begin
      ActiveRecord::Base.transaction do
        multiplier = transaction_type == TYPES[:buy] ? 1 : -1
        new_quantity = asset.quantity + (quantity * multiplier)

        if new_quantity >= 0
          if transaction_type == TYPES[:sell]
            asset.update!(
              quantity: new_quantity,
              purchase_price: calculate_new_average_price
            )
          else
            asset.update!(quantity: new_quantity)
          end
        else
          message = "Insufficient asset quantity for sell transaction"
          raise ActiveRecord::RecordInvalid.new(self), message
        end
      end
    rescue => e
      Rails.logger.error("Transaction update failed: #{e.message}")
      raise e # Re-raise the exception to trigger rollback
    end
  end

  def is_first_transaction?
    # Count existing transactions for this asset (excluding the current one)
    asset.transactions.where.not(id: id).count.zero?
  end

  def calculate_new_average_price
    return price if transaction_type == TYPES[:sell] || asset.quantity.zero?

    if transaction_type == TYPES[:buy]
      total_value = (asset.quantity * asset.purchase_price) + (quantity * price)
      total_quantity = asset.quantity + quantity
      total_value / total_quantity
    else
      asset.purchase_price
    end
  end
end
