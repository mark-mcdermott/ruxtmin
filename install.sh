#!/bin/bash
export PATH=/usr/local/bin:$PATH

echo -e "\n\n🦄 BACKEND\n\n"
cd ~/Desktop
rails new back --api --database=postgresql
cd back
rails db:drop db:create
bundle add rack-cors bcrypt jwt
rails active_storage:install
rails db:migrate
cat <<'EOF' | puravida config/initializers/cors.rb ~
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
~
EOF
echo -e "\n\n🦄 Health Controller\n\n"
rails g controller health index
cat <<'EOF' | puravida app/controllers/health_controller.rb ~
class HealthController < ApplicationController
  def index
    render json: { status: 'online' }
  end
end
~
EOF
echo -e "\n\n🦄  Users\n\n"
rails g model user name email avatar:attachment admin:boolean password_digest
sed -i -e 3,10d /Users/mmcdermott/Desktop/back/db/migrate/20231019135114_create_users.rb
awk 'NR==3 {print "\t\tcreate_table :users do |t|\n\t\t\tt.string :name, null: false\n\t\t\tt.string :email, null: false, index: { unique: true }\n\t\t\tt.boolean :admin, null: false, default: false\n\t\t\tt.string :password_digest\n\t\t\tt.timestamps\n\t\tend"} 1' /Users/mmcdermott/Desktop/back/db/migrate/20231019135114_create_users.rb > temp.txt && mv temp.txt /Users/mmcdermott/Desktop/back/db/migrate/20231019135114_create_users.rb
rails db:migrate
cat <<'EOF' | puravida app/models/user.rb ~
class User < ApplicationRecord
  has_one_attached :avatar
  has_secure_password
end
~
EOF
cat <<'EOF' | puravida app/controllers/users_controller.rb ~
class UsersController < ApplicationController
  
  def index
    @users = User.all.map do |u|
      { :id => u.id, :name => u.name, :email => u.email, :avatar => url_for(u.avatar), :admin => u.admin }
    end
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      avatar: url_for(@user.avatar),
      admin: @user.admin
    }
  end
  
  def create
    user = User.create user_params
    attach_main_pic(user) if admin_params[:avatar].present?
    if user.save
      render json: user, status: 200
    else
      render json: user, status: 400
    end
  end

  private

  def attach_main_pic(user)
    user.avatar.attach(admin_params[:avatar])
  end

  def user_params
    admin = admin_params[:admin].present? ? admin_params[:admin] : false
    {
      name: admin_params[:name],
      email: admin_params[:email],
      admin: admin,
      password: admin_params[:password],
    }
  end

  def admin_params
    params.permit(
      :name,
      :email,
      :avatar,
      :admin,
      :password
    )
  end
end
~
EOF
cat <<'EOF' | puravida config/routes.rb ~
Rails.application.routes.draw do
  resources :users
  get "health", to: "health#index"
end
~
EOF
echo -e "\n\n🦄  Seeds\n\n"
cp -a ~/Desktop/ruxtmin/assets ~/Desktop/back/app/
cat <<'EOF' | puravida db/seeds.rb ~
user = User.create(name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/michael-scott.png"), filename: "michael-scott.png")
user.save!
user = User.create(name: "Jim Halpert", email: "jimhalpert@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/jim-halpert.png"), filename: "jim-halpert.png")
user.save!
user = User.create(name: "Pam Beesly", email: "pambeesly@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/pam-beesly.png"), filename: "jim-halpert.png")
user.save!
~
EOF
rails db:seed
echo -e "\n\n🦄  Backend Auth\n\n"
cat <<'EOF' | puravida app/controllers/application_controller.rb ~
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
~
EOF
rails g controller Authentications
cat <<'EOF' | puravida app/controllers/authentications_controller.rb ~
class AuthenticationsController < ApplicationController
  skip_before_action :require_login
  
  def create
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      payload = { user_id: user.id, email: user.email }
      token = encode_token(payload)
      render json: { data: token, status: 200, message: 'You are logged in successfully' }
    else
      response_unauthorized
    end
  end
end
~
EOF
cat <<'EOF' | puravida app/controllers/users_controller.rb ~
class UsersController < ApplicationController
  skip_before_action :require_login, only: :create
  
  def index
    @users = User.all.map do |u|
      { :id => u.id, :name => u.name, :email => u.email, :avatar => url_for(u.avatar), :admin => u.admin }
    end
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      avatar: url_for(@user.avatar),
      admin: @user.admin
    }
  end
  
  def create
    user = User.create user_params
    attach_main_pic(user) if admin_params[:avatar].present?
    if user.save
      render json: user, status: 200
    else
      render json: user, status: 400
    end
  end

  private

  def attach_main_pic(user)
    user.avatar.attach(admin_params[:avatar])
  end

  def user_params
    admin = admin_params[:admin].present? ? admin_params[:admin] : false
    {
      name: admin_params[:name],
      email: admin_params[:email],
      admin: admin,
      password: admin_params[:password],
    }
  end

  def admin_params
    params.permit(
      :name,
      :email,
      :avatar,
      :admin,
      :password
    )
  end
end
~
EOF
cat <<'EOF' | puravida app/controllers/health_controller.rb ~
class HealthController < ApplicationController
  skip_before_action :require_login
  def index
    render json: { status: 'online' }
  end
end
~
EOF
cat <<'EOF' | puravida config/routes.rb ~
Rails.application.routes.draw do
  resources :users
  get "health", to: "health#index"
  post "login", to: "authentications#create"
  get "me", to: "application#user_from_token"
end
~
EOF

echo -e "\n\n🦄 FRONTEND\n\n"

echo -e "\n\n🦄 Setup\n\n"

cd ~/Desktop
(sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.1; echo -n $'\x20'; sleep 0.1; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n";) | npx create-nuxt-app front
cd front
npm install @picocss/pico @nuxtjs/auth@4.5.1 @fortawesome/fontawesome-svg-core @fortawesome/free-solid-svg-icons @fortawesome/free-brands-svg-icons @fortawesome/vue-fontawesome@latest-2
npm install --save-dev sass sass-loader@10