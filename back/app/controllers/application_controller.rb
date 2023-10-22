class ApplicationController < ActionController::API
  SECRET_KEY_BASE = Rails.application.credentials.secret_key_base
  before_action :require_login
  rescue_from Exception, with: :response_internal_server_error
  
  def user_from_token
    user = current_user.slice(:id,:email,:name,:admin)
    render json: { data: user, status: 200 }
  end

  def require_login
    response_unauthorized if current_user.blank?
  end
  
  def current_user
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
    if auth_header
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
  
  private 
  
    def auth_header
      request.headers['Authorization']
    end
end
