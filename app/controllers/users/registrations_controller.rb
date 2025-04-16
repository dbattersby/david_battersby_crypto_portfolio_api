# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json, :html
    before_action :set_minimum_password_length, only: [ :new ]
    skip_before_action :require_no_authentication, only: [ :new, :create ]
    # skip_before_action :authenticate_scope!, only: [:new, :create]
    before_action :configure_sign_up_params, only: [ :create ]
    before_action :set_page_title, only: [ :new ]

    # GET /resource/sign_up
    def new
      self.resource = resource_class.new
      render layout: "application"
    end

    # POST /resource
    def create
      build_resource(sign_up_params)

      resource.save
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, resource)
          respond_to do |format|
            format.html { redirect_to portfolio_path }
            format.json { render json: { status: { code: 200, message: "Signed up successfully." },
                          data: UserSerializer.new(resource).serializable_hash[:data][:attributes] }, status: :ok }
          end
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_to do |format|
            format.html { redirect_to after_inactive_sign_up_path_for(resource) }
            format.json { render json: { status: { code: 200, message: "Please #{resource.inactive_message} before continuing." } } }
          end
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" } },
                        status: :unprocessable_entity }
        end
      end
    end

    # GET /resource/edit
    # def edit
    #   super
    # end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_account_update_params
    #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    # end

    protected

    # The path used after sign up.
    def after_sign_up_path_for(resource)
      portfolio_path
    end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end

    private

    def set_minimum_password_length
      @minimum_password_length = resource_class.password_length.min if resource_class.respond_to?(:password_length)
    end

    def set_page_title
      @page_title = "Sign Up"
    end
  end
end
