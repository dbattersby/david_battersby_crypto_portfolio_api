class PortfolioSummaryQuery
  attr_reader :user

  def initialize(user, options = {})
    @user = user
    @force_refresh = options[:force_refresh] || false
    @portfolio_query = PortfolioAssetsQuery.new(user, force_refresh: @force_refresh)
  end

  def call
    portfolio_data = @portfolio_query.call
    return {} if portfolio_data.empty?

    {
      total_value: calculate_total_value(portfolio_data),
      asset_count: portfolio_data.size,
      assets: portfolio_data.values,
      best_performers: find_best_performers(portfolio_data),
      worst_performers: find_worst_performers(portfolio_data),
      distribution: calculate_distribution(portfolio_data),
      total_profit_loss: calculate_total_profit_loss(portfolio_data),
      last_updated: Time.current
    }
  end

  def calculate_total_value(portfolio_data = nil)
    portfolio_data ||= @portfolio_query.call
    portfolio_data.values.sum { |asset| asset[:total_value] }
  end

  def find_best_performers(portfolio_data = nil, limit = 3)
    portfolio_data ||= @portfolio_query.call
    portfolio_data.values
      .select { |asset| asset[:profit_loss] > 0 }
      .sort_by { |asset| -asset[:profit_loss] }
      .first(limit)
  end

  def find_worst_performers(portfolio_data = nil, limit = 3)
    portfolio_data ||= @portfolio_query.call
    portfolio_data.values
      .select { |asset| asset[:profit_loss] < 0 }
      .sort_by { |asset| asset[:profit_loss] }
      .first(limit)
  end

  def calculate_distribution(portfolio_data = nil)
    portfolio_data ||= @portfolio_query.call
    total = calculate_total_value(portfolio_data)
    
    return {} if total.zero?
    
    portfolio_data.values.each_with_object({}) do |asset, result|
      percentage = (asset[:total_value] / total) * 100
      result[asset[:symbol]] = {
        name: asset[:name],
        percentage: percentage,
        value: asset[:total_value]
      }
    end
  end

  def calculate_total_profit_loss(portfolio_data = nil)
    portfolio_data ||= @portfolio_query.call
    
    if portfolio_data.empty?
      return {
        absolute: 0,
        percentage: 0
      }
    end
    
    total_current_value = portfolio_data.values.sum { |asset| asset[:total_value] }
    total_purchase_value = portfolio_data.values.sum do |asset|
      asset[:avg_purchase_price] * asset[:total_quantity]
    end
    
    absolute_profit_loss = total_current_value - total_purchase_value
    percentage = total_purchase_value.zero? ? 0 : (absolute_profit_loss / total_purchase_value) * 100
    
    {
      absolute: absolute_profit_loss,
      percentage: percentage
    }
  end

  def monthly_performance
    # This would typically require historical data storage
    # For now, we'll just return a placeholder
    {
      message: "Historical data tracking would be required for this feature"
    }
  end

  # Get a summary of recent transactions
  def recent_activity(limit = 5)
    Transaction.where(user_id: user.id)
      .order(created_at: :desc)
      .limit(limit)
      .includes(:asset)
      .map do |transaction|
        {
          id: transaction.id,
          symbol: transaction.asset.symbol,
          name: transaction.asset.name,
          transaction_type: transaction.transaction_type,
          quantity: transaction.quantity,
          price: transaction.price,
          value: transaction.quantity * transaction.price,
          date: transaction.created_at
        }
      end
  end
end 