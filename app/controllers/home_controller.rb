class HomeController < ApplicationController
  before_action :skip_session_storage

  def index
  end

  private

  def skip_session_storage
    request.session_options[:skip] = true
  end
end
