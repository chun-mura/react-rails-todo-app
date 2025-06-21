class User < ApplicationRecord
  has_secure_password
  has_many :todos, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  def generate_jwt
    JWT.encode(
      { user_id: id, exp: 24.hours.from_now.to_i },
      ENV.fetch('JWT_SECRET_KEY', 'your-secret-key'),
      'HS256'
    )
  end
end
