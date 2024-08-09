class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
  has_one_attached :avatar

  before_create :set_uuid

  def avatar_url
    Rails.application.routes.url_helpers.rails_blob_url(self.avatar, only_path: true) if avatar.attached?
  end

  private

  def set_uuid
    self.uuid = SecureRandom.uuid if uuid.blank?
  end
end