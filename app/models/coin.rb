class Coin < ApplicationRecord
  validates :symbol, presence: true, uniqueness: true
  validates :name, presence: true
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :upcase_symbol

  private

  def upcase_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
end
