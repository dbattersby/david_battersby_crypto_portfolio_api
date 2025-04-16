module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [:signup, :login]

      def signup
        user = User.new(user_params)

        if user.save
          sign_in(user)
          render json: { 
            user: user.as_json(only: [:id, :email, :name]),
            message: "User registered successfully"
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          sign_in(user)
          render json: { 
            user: user.as_json(only: [:id, :email, :name]),
            message: "Logged in successfully"
          }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        sign_out(current_user)
        render json: { message: "Logged out successfully" }
      end

      private

      def user_params
        params.permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end
