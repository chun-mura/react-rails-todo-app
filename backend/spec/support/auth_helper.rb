module AuthHelper
  def auth_headers(user = nil)
    user ||= create(:user)
    token = user.generate_jwt_token
    { 'Authorization' => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
