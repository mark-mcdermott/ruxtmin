class ApplicationController < ActionController::API
  SECRET_KEY_BASE = Rails.application.credentials.secret_key_base
  before_action :require_login
  rescue_from Exception, with: :response_internal_server_error

  def require_login
    response_unauthorized if current_user_raw.blank?
  end

  # this is safe to send to the frontend, excludes password_digest, created_at, updated_at
  def user_from_token
    user = prep_raw_user(current_user_raw)
    render json: { data: user, status: 200 }
  end

  # unsafe/internal: includes password_digest, created_at, updated_at - we don't want those going to the frontend
  def current_user_raw
    if decoded_token.present?
      user_id = decoded_token[0]['user_id']
      @user = User.find_by(id: user_id)
    else
      nil
    end
  end

  def encode_token(payload)
    JWT.encode payload, SECRET_KEY_BASE, 'HS256'
  end

  def decoded_token
    if auth_header and auth_header.split(' ')[0] == "Bearer"
      token = auth_header.split(' ')[1]
      begin
        JWT.decode token, SECRET_KEY_BASE, true, { algorithm: 'HS256' }
      rescue JWT::DecodeError
        []
      end
    end
  end

  def response_unauthorized
    render status: 401, json: { status: 401, message: 'Unauthorized' }
  end
  
  def response_internal_server_error
    render status: 500, json: { status: 500, message: 'Internal Server Error' }
  end

  # We don't want to send the whole user record from the database to the frontend, so we only send what we need.
  # The db user row has password_digest (unsafe) and created_at and updated_at (extraneous).
  # We also change avatar from a weird active_storage object to just the avatar url before it gets to the frontend.
  def prep_raw_user(user)
    avatar = user.avatar.present? ? url_for(user.avatar) : nil
    user = user.admin ? user.slice(:id,:email,:name,:admin) : user.slice(:id,:email,:name)
    user['avatar'] = avatar
    user
  end
  
  private 
  
    def auth_header
      request.headers['Authorization']
    end

end