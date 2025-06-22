require 'rails_helper'

RSpec.describe AuthController, type: :request do
  describe 'POST /api/auth/register' do
    let(:valid_params) do
      {
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user and returns token' do
        expect {
          post '/api/auth/register', params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['token']).to be_present
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['user']['id']).to be_present
      end
    end

    context 'with invalid email' do
      it 'returns validation errors' do
        post '/api/auth/register', params: valid_params.merge(email: 'invalid-email')

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Email is invalid')
      end
    end

    context 'with duplicate email' do
      before { create(:user, email: 'test@example.com') }

      it 'returns validation errors' do
        post '/api/auth/register', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Email has already been taken')
      end
    end

    context 'with short password' do
      it 'returns validation errors' do
        post '/api/auth/register', params: valid_params.merge(
          password: '123',
          password_confirmation: '123'
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Password is too short (minimum is 6 characters)')
      end
    end

    context 'with password mismatch' do
      it 'returns validation errors' do
        post '/api/auth/register', params: valid_params.merge(
          password_confirmation: 'different_password'
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Password confirmation doesn't match Password")
      end
    end
  end

  describe 'POST /api/auth/login' do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns token and user info' do
        post '/api/auth/login', params: {
          email: 'test@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['token']).to be_present
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['user']['id']).to eq(user.id)
      end
    end

    context 'with invalid email' do
      it 'returns unauthorized error' do
        post '/api/auth/login', params: {
          email: 'nonexistent@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end

    context 'with invalid password' do
      it 'returns unauthorized error' do
        post '/api/auth/login', params: {
          email: 'test@example.com',
          password: 'wrong_password'
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end

  describe 'GET /api/auth/me' do
    let(:user) { create(:user) }

    context 'with valid token' do
      it 'returns current user info' do
        get '/api/auth/me', headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['id']).to eq(user.id)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get '/api/auth/me'

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Token is missing')
      end
    end
  end
end
