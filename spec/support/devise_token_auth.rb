module DeviseTokenAuthHelper
  def auth_headers(user)
    user.create_new_auth_token.merge({
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    })
  end
end

RSpec.configure do |config|
  config.include DeviseTokenAuthHelper, type: :request
end
