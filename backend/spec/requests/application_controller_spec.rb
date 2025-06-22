require 'rails_helper'

RSpec.describe ApplicationController, type: :request do
  describe 'GET /health' do
    it 'returns health status' do
      get '/health'

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('ok')
      expect(json_response['timestamp']).to be_present
    end
  end

  describe 'authentication' do
    let(:user) { create(:user) }
    let(:todo) { create(:todo, user: user) }

    context 'with valid token' do
      it 'allows access to protected endpoints' do
        get "/api/todos/#{todo.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get "/api/todos/#{todo.id}"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Token is missing')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get "/api/todos/#{todo.id}", headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid token')
      end
    end

    context 'with expired token' do
      it 'returns unauthorized error' do
        # 期限切れのトークンを作成
        expired_token = JWT.encode(
          { user_id: user.id, email: user.email, exp: 1.hour.ago.to_i },
          ENV.fetch('JWT_SECRET_KEY'),
          'HS256'
        )

        get "/api/todos/#{todo.id}", headers: { 'Authorization' => "Bearer #{expired_token}" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end
end
