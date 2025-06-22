class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:register, :login]

  def register
    user = User.new(user_params)

    if user.save
      token = user.generate_jwt_token
      render json: {
        token: token,
        user: { id: user.id, email: user.email }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = user.generate_jwt_token
      render json: {
        token: token,
        user: { id: user.id, email: user.email }
      }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def me
    render json: { user: { id: current_user.id, email: current_user.email } }
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
