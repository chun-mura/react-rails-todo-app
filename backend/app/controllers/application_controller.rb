class ApplicationController < ActionController::API
  before_action :authenticate_user!

  def health_check
    render json: { status: 'ok' }
  end

  private

  def authenticate_user!
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    begin
      decoded = JWT.decode(token, ENV.fetch('JWT_SECRET_KEY', 'your-secret-key'), true, { algorithm: 'HS256' })
      @current_user = User.find(decoded[0]['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
