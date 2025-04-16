module DeviseTokenAuth
  class SessionsController < DeviseTokenAuth::ApplicationController
    def new
      render :new
    end

    def create
      Rails.logger.debug "Sign in attempt with email: #{params[:email]}"
      
      @resource = User.find_by(email: params[:email])
      Rails.logger.debug "User found: #{@resource.present?}"
      
      if @resource && @resource.valid_password?(params[:password])
        Rails.logger.debug "Password valid, signing in user"
        
        # Create and store token for API requests
        @client_id = SecureRandom.urlsafe_base64(nil, false)
        @token = @resource.create_token(client_id: @client_id)
        @resource.save!

        # Set auth headers for API access
        response.headers.merge!(@resource.create_auth_header(@token, @client_id))

        # Sign in with Devise for browser-based access
        sign_in(:user, @resource)

        redirect_to portfolio_path
      else
        Rails.logger.debug "Invalid email or password"
        flash[:alert] = 'Invalid email or password'
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      if current_user
        # Clear tokens
        current_user.tokens = {}
        current_user.save!
        
        # Sign out with Devise
        sign_out(current_user)
      end
      redirect_to root_path
    end

    private

    def client_id
      @client_id ||= request.headers['client'] || cookies.signed[:client_id]
    end
  end
end 