module Api
  module V1
    class AssetsController < BaseController
      before_action :set_asset, only: [ :show, :update, :destroy, :value ]

      def index
        @assets = current_user.assets
        render json: @assets
      end

      def show
        render json: @asset
      end

      def create
        @asset = current_user.assets.new(asset_params)

        if @asset.save
          render json: @asset, status: :created
        else
          render_error(@asset.errors.full_messages)
        end
      end

      def update
        if @asset.update(asset_params)
          render json: @asset
        else
          render_error(@asset.errors.full_messages)
        end
      end

      def destroy
        @asset.destroy
        render json: { message: "Asset deleted successfully" }
      end

      def value
        # You would likely call an external API here to get the current value
        current_value = @asset.quantity * (rand(10000..20000) / 100.0) # Example calculation
        render json: {
          symbol: @asset.symbol,
          quantity: @asset.quantity,
          purchase_price: @asset.purchase_price,
          current_value: current_value
        }
      end

      private

      def set_asset
        @asset = current_user.assets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Asset not found", :not_found)
      end

      def asset_params
        params.require(:asset).permit(:symbol, :name, :quantity, :purchase_price)
      end
    end
  end
end
