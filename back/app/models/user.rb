class User < ApplicationRecord
  has_one_attached :avatar
  has_secure_password
  validates :email, format: { with: /\A(.+)@(.+)\z/, message: "Email invalid" }, uniqueness: { case_sensitive: false }, length: { minimum: 4, maximum: 254 }
end