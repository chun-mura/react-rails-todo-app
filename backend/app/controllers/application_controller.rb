class ApplicationController < ActionController::API
  before_action :authenticate_user!

  def health_check
    render json: { status: 'ok' }
  end

  # ヘルスチェックエンドポイント
  def health
    render json: { status: 'ok', timestamp: Time.current.iso8601 }
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { error: 'Token is missing' }, status: :unauthorized unless token

    begin
      decoded = JWT.decode(token, ENV.fetch('JWT_SECRET_KEY'), true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
