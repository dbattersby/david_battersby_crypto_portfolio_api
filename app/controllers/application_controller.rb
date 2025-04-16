# Application controller (parent for all controllers)
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  # This will handle CSRF protection for API requests
  skip_before_action :verify_authenticity_token, if: :json_request?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
  end

  def json_request?
    request.format.json? || request.path.include?('/api/')
  end

  # If accessing from API, respond with JSON error message
  def authenticate_user!
    if json_request?
      unless current_user
        render json: { error: "You need to sign in or sign up before continuing." }, status: :unauthorized
        return
      end
    else
      super
    end
  end
end
