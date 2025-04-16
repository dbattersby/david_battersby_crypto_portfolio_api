class TransactionsQuery
  attr_reader :user
  
  def initialize(user)
    @user = user
  end
  
  # Get all transactions with optional filters
  def all_transactions(options = {})
    transactions = user.transactions.includes(:asset)
    
    # Apply filters
    transactions = transactions.where(asset: {symbol: options[:symbol]}) if options[:symbol].present?
    transactions = transactions.where(transaction_type: options[:transaction_type]) if options[:transaction_type].present?
    transactions = transactions.where('transactions.created_at >= ?', options[:start_date]) if options[:start_date].present?
    transactions = transactions.where('transactions.created_at <= ?', options[:end_date]) if options[:end_date].present?
    
    # Apply sorting
    sort_column = options[:sort_by] || 'transactions.created_at'
    sort_direction = options[:sort_direction] || 'desc'
    transactions = transactions.order("#{sort_column} #{sort_direction}")
    
    transactions
  end
  
  # Get transactions grouped by asset symbol
  def grouped_by_asset
    user.transactions
      .includes(:asset)
      .group_by { |t| t.asset.symbol }
  end
  
  # Get transactions grouped by type (buy/sell)
  def grouped_by_type
    user.transactions
      .includes(:asset)
      .group_by(&:transaction_type)
  end
  
  # Get transactions grouped by month
  def grouped_by_month
    user.transactions
      .includes(:asset)
      .group_by { |t| t.created_at.beginning_of_month }
  end
  
  # Calculate total value of all buy transactions
  def total_buy_value
    user.transactions
      .where(transaction_type: 'buy')
      .sum('price * quantity')
  end
  
  # Calculate total value of all sell transactions
  def total_sell_value
    user.transactions
      .where(transaction_type: 'sell')
      .sum('price * quantity')
  end
  
  # Calculate realized profit/loss from sell transactions
  def realized_profit_loss
    total_sell_value - total_buy_value
  end
  
  # Get most recent transactions, limited by count
  def recent_transactions(limit = 5)
    user.transactions
      .includes(:asset)
      .order(created_at: :desc)
      .limit(limit)
  end
  
  # Get largest transactions by value
  def largest_transactions(limit = 5)
    user.transactions
      .includes(:asset)
      .select('transactions.*, (price * quantity) as total_value')
      .order('total_value DESC')
      .limit(limit)
  end
  
  # Get transaction volume by asset (sum of all transaction values)
  def volume_by_asset
    user.transactions
      .includes(:asset)
      .group('assets.symbol')
      .sum('price * quantity')
  end
end 