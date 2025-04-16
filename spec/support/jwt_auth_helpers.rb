module JwtAuthHelpers
  def auth_headers(user)
    headers = {}
    headers['Accept'] = 'application/json'
    headers['Content-Type'] = 'application/json'

    # Generate JWT token for the user
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)[0]
    headers['Authorization'] = "Bearer #{token}"

    headers
  end
end

RSpec.configure do |config|
  config.include JwtAuthHelpers, type: :request
end
