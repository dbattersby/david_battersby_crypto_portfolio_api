class Asset < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  validates :symbol, presence: true
  validates :name, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Virtual attributes
  attr_accessor :initial_purchase_price, :transaction_count, :weighted_purchase_price

  before_validation :set_purchase_price_from_initial

  # Add quantity with proper weighted average price calculation
  def add_quantity(quantity_to_add, price)
    return false if quantity_to_add <= 0
    
    # Calculate new weighted average purchase price
    total_value_before = self.quantity * (self.purchase_price || 0)
    new_value = quantity_to_add * price
    total_quantity = self.quantity + quantity_to_add
    weighted_avg_price = (total_value_before + new_value) / total_quantity
    
    # Update asset
    self.quantity = total_quantity
    self.purchase_price = weighted_avg_price
    save
  end
  
  # Sell quantity with validation
  def sell_quantity(quantity_to_sell)
    return false if quantity_to_sell <= 0
    return false if quantity_to_sell > self.quantity
    
    # Update asset with new quantity
    self.quantity -= quantity_to_sell
    save
  end
  
  # Check if there's enough quantity to sell
  def has_sufficient_quantity?(quantity_to_check)
    self.quantity >= quantity_to_check
  end

  def current_price
    # Use the database value if available
    @current_price ||= begin
      # First try to get from database
      db_coin = Coin.find_by(symbol: symbol.upcase)
      if db_coin&.current_price.present?
        db_coin.current_price
      else
        # Fall back to service which will use cache or fallback data
        CryptocurrencyService.get_current_price(symbol)
      end
    end
  end

  def current_value
    quantity * current_price if current_price
  end

  def profit_loss_percentage
    purchase_price_to_use = weighted_purchase_price || purchase_price
    return 0 if purchase_price_to_use.to_f.zero? || current_price.nil?
    ((current_price - purchase_price_to_use.to_f) / purchase_price_to_use.to_f) * 100
  end

  def price_change_24h
    @price_change_24h ||= Coin.find_by(symbol: symbol.upcase)&.price_change_24h || "-"
  end

  # Helper method to get the initial transaction's purchase price
  def purchase_price
    initial_purchase_price || initial_transaction&.price || 0
  end

  # Returns the related Coin record if available
  def coin
    @coin ||= Coin.find_by(symbol: symbol.upcase)
  end

  private

  def set_purchase_price_from_initial
    self.purchase_price = initial_purchase_price if initial_purchase_price.present?
  end

  def initial_transaction
    transactions.order(created_at: :asc).first
  end
end
