# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json, :html
    skip_before_action :verify_signed_out_user, only: [ :destroy ]
    skip_before_action :require_no_authentication, only: [ :new, :create ]
    before_action :set_page_title, only: [ :new ]

    # GET /login
    def new
      self.resource = resource_class.new
      render layout: "application"
    end

    # POST /users/sign_in
    def create
      self.resource = warden.authenticate!(auth_options)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_to do |format|
        format.html { redirect_to portfolio_path }
        format.json { render json: {
          status: {
            code: 200, message: "Logged in successfully.",
            data: { user: UserSerializer.new(resource).serializable_hash[:data][:attributes] }
          }
        }, status: :ok }
      end
    end

    # DELETE /users/sign_out
    def destroy
      sign_out(current_user) if current_user
      yield if block_given?
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { render json: { status: 200, message: "Logged out successfully." }, status: :ok }
      end
    end

    protected

    def after_sign_in_path_for(resource)
      portfolio_path
    end

    private

    def respond_to_on_destroy
      # Sign out without storing the result as it's not used
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)

      respond_to do |format|
        format.html { redirect_to root_path }
        format.json do
          if request.headers["Authorization"].present?
            jwt_payload = JWT.decode(request.headers["Authorization"].split(" ").last, Rails.application.credentials.devise_jwt_secret_key!).first
            current_user = User.find(jwt_payload["sub"])
          end

          if current_user
            render json: {
              status: 200,
              message: "Logged out successfully."
            }, status: :ok
          else
            render json: {
              status: 401,
              message: "Couldn't find an active session."
            }, status: :unauthorized
          end
        end
      end
    end

    def set_page_title
      @page_title = "Sign In"
    end
  end
end
