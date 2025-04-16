module Api
  module V1
    class TransactionsController < BaseController
      def index
        @transactions = current_user.transactions
        render json: @transactions
      end

      def show
        @transaction = current_user.transactions.find(params[:id])
        render json: @transaction
      rescue ActiveRecord::RecordNotFound
        render_error("Transaction not found", :not_found)
      end

      def create
        @transaction = current_user.transactions.new(transaction_params)

        if @transaction.save
          render json: @transaction, status: :created
        else
          render_error(@transaction.errors.full_messages)
        end
      end

      private

      def transaction_params
        params.require(:transaction).permit(:asset_id, :transaction_type, :quantity, :price)
      end
    end
  end
end
