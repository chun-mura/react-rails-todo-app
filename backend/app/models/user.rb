class User < ApplicationRecord
  has_secure_password
  has_many :todos, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create

  def generate_jwt_token
    JWT.encode(
      { user_id: id, email: email, exp: 24.hours.from_now.to_i },
      ENV.fetch('JWT_SECRET_KEY'),
      'HS256'
    )
  end
end
