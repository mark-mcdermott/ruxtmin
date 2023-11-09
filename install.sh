!/bin/bash
export PATH=/usr/local/bin:$PATH

echo -e "\n\n🦄 BACKEND\n\n"
cd ~/Desktop
rails new back --api --database=postgresql --skip-test-unit
cd back
rails db:drop db:create
bundle add rack-cors bcrypt jwt pry
bundle add rspec-rails factory_bot_rails --group "development, test"
rails active_storage:install
rails generate rspec:install
rails db:migrate
cp -a ~/Desktop/ruxtmin/assets ~/Desktop/back/app/
puravida spec/fixtures/files/images
cp -a ~/Desktop/ruxtmin/assets/images/office-avatars ~/Desktop/back/spec/fixtures/files/images
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
  skip_before_action :require_login
  def index
    render json: { status: 'online' }
  end
end
~
EOF
cat <<'EOF' | puravida spec/requests/health_spec.rb ~
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Testing" do
  describe "GET /health" do
    it "returns success" do
      get("/health")

      response_data = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(response_data['status']).to eq('online')
    end

  end

end
~
EOF

echo -e "\n\n🦄  Users\n\n"
rails g scaffold user name email avatar:attachment admin:boolean password_digest
MIGRATION_FILE=$(find /Users/mmcdermott/Desktop/back/db/migrate -name "*_create_users.rb")
sed -i -e 3,10d $MIGRATION_FILE
awk 'NR==3 {print "\t\tcreate_table :users do |t|\n\t\t\tt.string :name, null: false\n\t\t\tt.string :email, null: false, index: { unique: true }\n\t\t\tt.boolean :admin, default: false\n\t\t\tt.string :password_digest\n\t\t\tt.timestamps\n\t\tend"} 1' $MIGRATION_FILE > temp.txt && mv temp.txt $MIGRATION_FILE
rails db:migrate
cat <<'EOF' | puravida app/models/user.rb ~
class User < ApplicationRecord
  has_one_attached :avatar
  has_secure_password
  validates :email, format: { with: /\A(.+)@(.+)\z/, message: "Email invalid" }, uniqueness: { case_sensitive: false }, length: { minimum: 4, maximum: 254 }
end
~
EOF
cat <<'EOF' | puravida app/controllers/users_controller.rb ~
class UsersController < ApplicationController
  before_action :set_user, only: %i[ show update destroy ]
  skip_before_action :require_login, only: :create

  # GET /users
  def index
    @users = User.all.map { |user| prep_raw_user(user) }
    render json: @users
  end

  # GET /users/1
  def show
    render json: prep_raw_user(@user)
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      render json: prep_raw_user(@user), status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      render json: prep_raw_user(@user)
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params['avatar'] = params['avatar'].blank? ? nil : params['avatar'] # if no avatar is chosen on signup page, params['avatar'] comes in as a blank string, which throws a 500 error at User.new(user_params). This changes any params['avatar'] blank string to nil, which is fine in User.new(user_params).
      params.permit(:name, :email, :avatar, :admin, :password)
    end
    
end
~
EOF

cat <<'EOF' | puravida spec/requests/users_spec.rb ~
# frozen_string_literal: true
require 'open-uri'
require 'rails_helper'
RSpec.describe "/users", type: :request do
  let(:valid_create_user_1_params) { { name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password" } }
  let(:user_1_attachment) { "/spec/fixtures/files/images/office-avatars/michael-scott.png" }
  let(:user_1_image) { "michael-scott.png" }
  let(:valid_create_user_2_params) { { name: "Jim Halpert", email: "jimhalpert@dundermifflin.com", admin: "false", password: "password" } }
  let(:user_2_attachment) { "/spec/fixtures/files/images/office-avatars//jim-halpert.png" }
  let(:user_2_image) { "jim-halpert.png" }
  let(:invalid_create_user_1_params) { { name: "Michael Scott", email: "test", admin: "true", password: "password" } }
  let(:invalid_create_user_2_params) { { name: "Jim Halpert", email: "test2", admin: "false", password: "password" } }
  let(:valid_user_1_login_params) { { email: "michaelscott@dundermifflin.com",  password: "password" } }
  let(:valid_user_2_login_params) { { email: "jimhalpert@dundermifflin.com",  password: "password" } }
  let(:invalid_patch_params) { { email: "test" } }
  let(:uploaded_image_path) { Rails.root.join '/spec/fixtures/files/images/office-avatars/michael-scott.png' }
  let(:uploaded_image) { Rack::Test::UploadedFile.new uploaded_image_path, 'image/png' }

  describe "GET /index" do
    context "with valid auth header" do
      it "renders a successful response" do
        user1 = User.create! valid_create_user_1_params
        user1.avatar.attach(io: URI.open("#{Rails.root}" + user_1_attachment), filename: user_1_image)
        user1.save!
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        get users_url, headers: header, as: :json
        expect(response).to be_successful
      end
      it "gets two users (one with avatar, one without)" do
        user1 = User.create! valid_create_user_1_params
        user1.avatar.attach(io: URI.open("#{Rails.root}" + user_1_attachment), filename: user_1_image)
        user1.save!
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        get users_url, headers: header, as: :json
        expect(JSON.parse(response.body).length).to eq 2
        expect(JSON.parse(response.body)[0]).to include("id","name","email","admin","avatar")
        expect(JSON.parse(response.body)[0]).not_to include("password_digest","password")
        expect(JSON.parse(response.body)[0]['name']).to eq("Michael Scott")
        expect(JSON.parse(response.body)[0]['email']).to eq("michaelscott@dundermifflin.com")
        expect(JSON.parse(response.body)[0]['admin']).to eq(true)
        expect(JSON.parse(response.body)[0]['avatar']).to be_kind_of(String)
        expect(JSON.parse(response.body)[0]['avatar']).to match(/http.*\michael-scott\.png/)
        expect(JSON.parse(response.body)[0]['password']).to be_nil
        expect(JSON.parse(response.body)[0]['password_digest']).to be_nil
        expect(JSON.parse(response.body)[1]).to include("id","name","email","avatar")
        expect(JSON.parse(response.body)[1]).not_to include("admin","password_digest","password")
        expect(JSON.parse(response.body)[1]['name']).to eq("Jim Halpert")
        expect(JSON.parse(response.body)[1]['email']).to eq("jimhalpert@dundermifflin.com")
        expect(JSON.parse(response.body)[1]['admin']).to be_nil
        expect(JSON.parse(response.body)[1]['avatar']).to be_nil
        expect(JSON.parse(response.body)[1]['password']).to be_nil
        expect(JSON.parse(response.body)[1]['password_digest']).to be_nil
      end
    end

    context "with invalid auth header" do
      it "renders a 401 response" do
        User.create! valid_create_user_1_params
        get users_url, headers: invalid_auth_header, as: :json
        expect(response).to have_http_status(401)
      end
      it "renders a 401 response" do
        User.create! valid_create_user_1_params
        get users_url, headers: poorly_formed_header(valid_create_user_2_params), as: :json
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "GET /show" do
    context "with valid auth header" do
      it "renders a successful response" do
        user1 = User.create! valid_create_user_1_params
        user1.avatar.attach(io: URI.open("#{Rails.root}" + user_1_attachment), filename: user_1_image)
        user1.save!
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        get user_url(user1), headers: header, as: :json
        expect(response).to be_successful
      end
      it "gets one user (with avatar)" do
        user1 = User.create! valid_create_user_1_params
        user1.avatar.attach(io: URI.open("#{Rails.root}" + user_1_attachment), filename: user_1_image)
        user1.save!
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        get user_url(user1), headers: header, as: :json
        expect(JSON.parse(response.body)).to include("id","name","email","admin","avatar")
        expect(JSON.parse(response.body)).not_to include("password_digest","password")
        expect(JSON.parse(response.body)['name']).to eq("Michael Scott")
        expect(JSON.parse(response.body)['email']).to eq("michaelscott@dundermifflin.com")
        expect(JSON.parse(response.body)['admin']).to eq(true)
        expect(JSON.parse(response.body)['avatar']).to be_kind_of(String)
        expect(JSON.parse(response.body)['avatar']).to match(/http.*\michael-scott\.png/)
        expect(JSON.parse(response.body)['password']).to be_nil
        expect(JSON.parse(response.body)['password_digest']).to be_nil
      end
      it "gets one user (without avatar)" do
        user1 = User.create! valid_create_user_1_params
        user1.avatar.attach(io: URI.open("#{Rails.root}" + user_1_attachment), filename: user_1_image)
        user1.save!
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        get user_url(user2), headers: header, as: :json
        expect(JSON.parse(response.body)).to include("id","name","email","avatar")
        expect(JSON.parse(response.body)).not_to include("admin","password_digest","password")
        expect(JSON.parse(response.body)['name']).to eq("Jim Halpert")
        expect(JSON.parse(response.body)['email']).to eq("jimhalpert@dundermifflin.com")
        expect(JSON.parse(response.body)['admin']).to be_nil
        expect(JSON.parse(response.body)['avatar']).to be_nil
        expect(JSON.parse(response.body)['password']).to be_nil
        expect(JSON.parse(response.body)['password_digest']).to be_nil
      end
    end
    context "with invalid auth header" do
      it "renders a 401 response" do
        user = User.create! valid_create_user_1_params
        get user_url(user), headers: invalid_auth_header, as: :json
        expect(response).to have_http_status(401)
      end
      it "renders a 401 response" do
        user = User.create! valid_create_user_1_params
        get user_url(user), headers: poorly_formed_header(valid_create_user_2_params), as: :json
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new User (without avatar)" do
        expect { post users_url, params: valid_create_user_1_params }
          .to change(User, :count).by(1)
      end
      it "renders a JSON response with new user (with avatar)" do  
        file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/images/office-avatars/michael-scott.png"))
        valid_create_user_1_params['avatar'] = file
        post users_url, params: valid_create_user_1_params        
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
        expect(JSON.parse(response.body)).to include("id","name","email","admin","avatar")
        expect(JSON.parse(response.body)).not_to include("password_digest","password")
        expect(JSON.parse(response.body)['name']).to eq("Michael Scott")
        expect(JSON.parse(response.body)['email']).to eq("michaelscott@dundermifflin.com")
        expect(JSON.parse(response.body)['admin']).to eq(true)
        expect(JSON.parse(response.body)['avatar']).to be_kind_of(String)
        expect(JSON.parse(response.body)['avatar']).to match(/http.*\michael-scott\.png/)
        expect(JSON.parse(response.body)['password']).to be_nil
        expect(JSON.parse(response.body)['password_digest']).to be_nil
      end
    end
    context "with invalid parameters" do
      it "does not create a new User" do
        expect { post users_url, params: invalid_create_user_2_params, as: :json}
          .to change(User, :count).by(0)
      end
      it "renders a JSON error response" do
        post users_url, params: invalid_create_user_2_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
    context "with valid auth header" do
      it "creates a new User" do
        user1 = User.create! valid_create_user_1_params
        header = header_from_user(user1,valid_user_1_login_params)
        expect { post users_url, headers: header, params: valid_create_user_2_params, as: :json }
          .to change(User, :count).by(1)
      end
      it "renders a JSON response with the new user" do
        user1 = User.create! valid_create_user_1_params
        header = header_from_user(user1,valid_user_1_login_params)
        post users_url, params: valid_create_user_2_params, as: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do

      it "updates the requested user's name" do
        user1 = User.create! valid_create_user_1_params
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        patch user_url(user1), params: { name: "Updated Name!!"}, headers: header, as: :json
        user1.reload
        expect(JSON.parse(response.body)['name']).to eq "Updated Name!!"
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "updates the requested user's avatar" do
        avatar = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/images/office-avatars/michael-scott.png"))
        valid_create_user_1_params['avatar'] = avatar
        user1 = User.create! valid_create_user_1_params   
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        updated_avatar = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/office-avatars/jim-halpert.png'))
        valid_create_user_1_params['avatar'] = updated_avatar
        patch user_url(user1), params: valid_create_user_1_params, headers: header
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
        expect(JSON.parse(response.body)['name']).to eq("Michael Scott")
        expect(JSON.parse(response.body)['avatar']).to be_kind_of(String)
        expect(JSON.parse(response.body)['avatar']).to match(/http.*\jim-halpert\.png/)
      end
    end

    context "with invalid parameters" do
      it "renders a JSON response with errors for the user" do
        user1 = User.create! valid_create_user_1_params
        user2 = User.create! valid_create_user_2_params
        header = header_from_user(user2,valid_user_2_login_params)
        patch user_url(user1), params: invalid_patch_params, headers: header, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested user (without avatar)" do
      user1 = User.create! valid_create_user_1_params
      user2 = User.create! valid_create_user_2_params
      header = header_from_user(user2,valid_user_2_login_params)
      expect {
        delete user_url(user1), headers: header, as: :json
      }.to change(User, :count).by(-1)
    end
    it "destroys the requested user (with avatar)" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/images/office-avatars/michael-scott.png"))
      valid_create_user_1_params['avatar'] = file
      user1 = User.create! valid_create_user_1_params
      user2 = User.create! valid_create_user_2_params
      header = header_from_user(user2,valid_user_2_login_params)
      expect {
        delete user_url(user1), headers: header, as: :json
      }.to change(User, :count).by(-1)
    end
  end
end

private 

def token_from_user(user,login_params)
  post "/login", params: login_params
  token = JSON.parse(response.body)['data']
end

def valid_token(create_user_params)
  user = User.create(create_user_params)
  post "/login", params: valid_user_1_login_params
  token = JSON.parse(response.body)['data']
end

def valid_auth_header_from_token(token)
  auth_value = "Bearer " + token
  { Authorization: auth_value }
end

def valid_auth_header_from_user_params(create_user_params)
  token = valid_token(create_user_params)
  auth_value = "Bearer " + token
  { Authorization: auth_value }
end

def header_from_user(user,login_params)
  token = token_from_user(user,login_params)
  auth_value = "Bearer " + token
  { Authorization: auth_value }
end

def invalid_auth_header
  auth_value = "Bearer " + "xyz"
  { Authorization: auth_value }
end

def poorly_formed_header(create_user_params)
  token = valid_token(create_user_params)
  auth_value = "Bears " + token
  { Authorization: auth_value }
end

def blob_for(name)
  ActiveStorage::Blob.create_and_upload!(
    io: File.open(Rails.root.join(file_fixture(name)), 'rb'),
    filename: name,
    content_type: 'image/png' # Or figure it out from `name` if you have non-JPEGs
  )
end
~
EOF

echo -e "\n\n🦄  /me Route (Application Controller)\n\n"
cat <<'EOF' | puravida app/controllers/application_controller.rb ~
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
~
EOF
cat <<'EOF' | puravida spec/requests/application_spec.rb ~
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/me", type: :request do
  let(:valid_login_params) { { email: "michaelscott@dundermifflin.com",  password: "password" } }
  let(:invalid_login_params) { { email: "michaelscott@dundermifflin.com",  password: "testing" } }
  let(:create_user_params) { { name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password" }}
  let(:invalid_token_header) { { Authorization: "Bearer xyz123"}}
  describe "GET /me" do

    context "without auth header" do
      it "returns http success" do
        get "/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context "with invalid token header" do
      it "returns http success" do
        get "/me", headers: invalid_token_header
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid token, but poorly formed auth header" do
      it "returns http success" do
        get "/me", headers: _valid_token_but_poorly_formed_auth_header
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid auth header" do
      it "returns http success" do
        get "/me", headers: _valid_auth_header
        expect(response).to have_http_status(:success)
      end
    end
  end
end

private

def _valid_token
  user = User.create(create_user_params)
  post "/login", params: valid_login_params
  token = JSON.parse(response.body)['data']
end

def _valid_auth_header
  auth_value = "Bearer " + _valid_token
  { Authorization: auth_value }
end

def _valid_token_but_poorly_formed_auth_header
  auth_value = "Bears " + _valid_token
  { Authorization: auth_value }
end
~
EOF

echo -e "\n\n🦄  /login Route (Authentications Controller)\n\n"
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
cat <<'EOF' | puravida spec/requests/authentications_spec.rb ~
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/login", type: :request do
  let(:valid_login_params) { { email: "michaelscott@dundermifflin.com",  password: "password" } }
  let(:invalid_login_params) { { email: "michaelscott@dundermifflin.com",  password: "testing" } }
  let(:create_user_params) { { name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password" }}
  describe "POST /login" do
    context "without params" do
      it "returns unauthorized" do
        post "/login"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "POST /login" do
    context "with invalid params" do
      it "returns unauthorized" do
        post "/login", params: invalid_login_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "POST /login" do
    context "with valid params" do
      it "returns unauthorized" do
        user = User.create(create_user_params)
        post "/login", params: valid_login_params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['message']).to eq "You are logged in successfully"
        expect(JSON.parse(response.body)['data']).to match(/^(?:[\w-]*\.){2}[\w-]*$/)
      end
    end
  end
end
~
EOF

echo -e "\n\n🦄  Widgets\n\n"
rails g scaffold widget name description image:attachment user:references
rails db:migrate

cat <<'EOF' | puravida app/controllers/widgets_controller.rb ~
class WidgetsController < ApplicationController
  before_action :set_widget, only: %i[ show update destroy ]

  # GET /widgets
  def index
    @widgets = Widget.all.map do |w|
      image = w.image.present? ? url_for(w.image) : nil
      { :id => w.id, :name => w.name, :description => w.description, :image => image, :user_id => w.user_id }
    end
    render json: @widgets
  end

  # GET /widgets/1
  def show
    image = @widget.image.present? ? url_for(@widget.image) : nil
    user_name = User.find(@widget.user_id).name
    render json: { id: @widget.id, name: @widget.name, description: @widget.description, image: image, userId: @widget.user_id, userName: user_name }
  end

  # POST /widgets
  def create
    @widget = Widget.new(widget_params)

    if @widget.save
      render json: @widget, status: :created, location: @widget
    else
      render json: @widget.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /widgets/1
  def update
    if @widget.update(widget_params)
      render json: @widget
    else
      render json: @widget.errors, status: :unprocessable_entity
    end
  end

  # DELETE /widgets/1
  def destroy
    @widget.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_widget
      @widget = Widget.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def widget_params
      params.permit(:name, :description, :image, :user_id)
    end
end
~
EOF

cat <<'EOF' | puravida spec/requests/widgets_spec.rb ~
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/widgets API Testing", type: :request do
  let(:user_1_params) { { name: "Michael Scott", email: SecureRandom.hex + "@mail.com", admin: true, password: "password" } }
  let(:user_2_params) { { name: "Jim Halpert", email: SecureRandom.hex + "@mail.com", admin: false, password: "password" } }
  let(:widget_1_params) { { name: "Michael's widget", description: "Michael's widget description" } }
  let(:widget_1_patch_params) { { name: "Michael's widget!!" } }
  let(:widget_2_params) { { name: "Jim's widget", description: "Jim's widget description" } }
  let(:widget_3_params) { { name: "Pam's widget", description: "Pam's widget description" } }
  let(:valid_attributes_without_user_id) { { name: "name", description: "description" } }
  let(:invalid_attributes) { { name: "name", test: "test" } }

  before :each do
    create_users_and_widgets
  end

  describe "GET /widgets" do
    it "without token, returns 401" do
      get widgets_path
      expect(response).to have_http_status(401)
    end
    it "returns widgets 1 & 2" do
      get widgets_path, headers: auth_header
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to include("id" => an_int, "name" => "Michael's widget","description" => "Michael's widget description", "image" => nil, "user_id" => an_int)
      expect(JSON.parse(response.body)).to include("id" => an_int, "name" => "Jim's widget","description" => "Jim's widget description", "image" => nil, "user_id" => an_int)
    end

  describe "GET /widgets/:id" do
    it "without token, returns 401" do
      get widget_path(@user1)
      expect(response).to have_http_status(401)
    end
    it "returns widget 1" do
      get widget_path(@widget1), headers: auth_header
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to include("id" => an_int, "name" => "Michael's widget","description" => "Michael's widget description", "image" => nil, "userId" => an_int)
      expect(JSON.parse(response.body)).not_to include("name" => "Jim's widget","description" => "Jim's widget description")
    end
    it "returns widget 2" do
      get widget_path(@widget2), headers: auth_header
      expect(JSON.parse(response.body)).to include("id" => an_int, "name" => "Jim's widget","description" => "Jim's widget description", "image" => nil, "userId" => an_int)
      expect(JSON.parse(response.body)).not_to include("name" => "Michaels's widget","description" => "Michaels's widget description")
    end
  end

  describe "POST /widgets" do
    it "without token, returns 401" do
      post widgets_url, params: widget_3_params
      expect(response).to have_http_status(401)
    end
    it "without user_id param, returns 422" do
      post widgets_path, headers: auth_header, params: valid_attributes_without_user_id
      expect(response).to have_http_status(422)
    end
    it "returns 201" do
      post widgets_path, headers: auth_header, params: valid_attributes_without_user_id.merge!(:user_id => @user1.id)
      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)).to include("id" => an_int, "name" => "name","description" => "description", "user_id" => an_int)
    end
  end

  describe "PATCH /widgets" do
    it "without token, returns 401" do
      patch widget_path(@widget1), params: widget_1_patch_params
      expect(response).to have_http_status(401)
    end
    it "without params, still returns 200" do
      patch widget_path(@widget1), headers: auth_header
      expect(response).to have_http_status(200)
    end
    it "returns updated widget" do
      patch widget_path(@widget1), headers: auth_header, params: widget_1_patch_params
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to include("name" => "Michael's widget!!")
    end
  end

  describe "DELETE /widgets/:id" do
    it "destroys requested widget" do
      new_widget = Widget.create! valid_attributes_without_user_id.merge!(:user_id => @user1.id)
      expect {
        delete widget_url(new_widget), headers: auth_header, as: :json
      }.to change(Widget, :count).by(-1)
    end
  end
end

def create_users
  @user1 = User.create(name: user_1_params[:name], email: user_1_params[:email], admin: user_1_params[:admin], password: user_1_params[:password])
  @user2 = User.create(name: user_2_params[:name], email: user_2_params[:email], admin: user_2_params[:admin], password: user_2_params[:password])
end

def create_widgets
  @widget1 = Widget.create! widget_1_params.merge!(:user_id => @user1.id)
  @widget2 = Widget.create! widget_2_params.merge!(:user_id => @user2.id)
end

def create_users_and_widgets
  create_users
  create_widgets
end

def auth_header
  post ("/login"), params: { email: user_1_params[:email], password: user_1_params[:password] }
  { Authorization: "Token " + (JSON.parse(response.body))['data'] }
end

def an_int
  be_a_kind_of(Integer)
end
~
EOF




echo -e "\n\n🦄  Routes\n\n"
cat <<'EOF' | puravida config/routes.rb ~
Rails.application.routes.draw do
  resources :users
  resources :widgets
  get "health", to: "health#index"
  post "login", to: "authentications#create"
  get "me", to: "application#user_from_token"
end
~
EOF

echo -e "\n\n🦄  Seeds\n\n"
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
# widget = Widget.create(name: "Wrenches", description: "Michael's wrenches", user_id: 1)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/allen-wrenches.jpg"), filename: "allen-wrenches.jpg")
# widget.save!
# widget = Widget.create(name: "Bolts", description: "Michael's bolts", user_id: 1)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/bolts.jpg"), filename: "bolts.jpg")
# widget.save!
# widget = Widget.create(name: "Brackets", description: "Jim's brackets", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/brackets.png"), filename: "brackets.png")
# widget.save!
# widget = Widget.create(name: "Nuts", description: "Jim's nuts", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/nuts.jpg"), filename: "nuts.jpg")
# widget.save!
# widget = Widget.create(name: "Pipes", description: "Jim's pipes", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/pipes.jpg"), filename: "pipes.jpg")
# widget.save!
# widget = Widget.create(name: "Screws", description: "Pam's screws", user_id: 3)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/screws.jpg"), filename: "screws.jpg")
# widget.save!
# widget = Widget.create(name: "Washers", description: "Pam's washers", user_id: 3)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/washers.jpg"), filename: "washers.jpg")
# widget.save!
~
EOF
rails db:seed
rm -rf spec/factories
rm -rf spec/models
rm -rf spec/routing




echo -e "\n\n🦄 FRONTEND\n\n"

echo -e "\n\n🦄 Setup\n\n"

cd ~/Desktop
npx create-nuxt-app front
cd front
npm install @picocss/pico @nuxtjs/auth@4.5.1 @fortawesome/fontawesome-svg-core @fortawesome/free-solid-svg-icons @fortawesome/free-brands-svg-icons @fortawesome/vue-fontawesome@latest-2
npm install --save-dev sass sass-loader@10
cat <<'EOF' | puravida assets/scss/main.scss ~
@import "node_modules/@picocss/pico/scss/pico.scss";

// Pico overrides 
// $primary-500: #e91e63;

h1 {
  margin: 4rem 0
}

.no-margin {
  margin: 0
}

.small-bottom-margin {
  margin: 0 0 0.5rem
}

.big-bottom-margin {
  margin: 0 0 8rem
}

.half-width {
  margin: 0 0 4rem;
  width: 50%;
}

nav img {
  width: 40px;
  border-radius: 50%;
  border: 3px solid var(--primary);
}

article img {
  margin-bottom: var(--typography-spacing-vertical);
  width: 250px;
}

ul.features { 
  margin: 0 0 2.5rem 1rem;
  li {
    margin: 0;
    padding: 0;
  }
}

.aligned-columns {
  margin: 0 0 2rem;
  p {
    margin: 0;
    span {
      margin: 0 0.5rem 0 0;
      display: inline-block;
      width: 8rem;
      text-align: right;
      font-weight: bold;
    }
  }
}
~
EOF
cat <<'EOF' | puravida nuxt.config.js ~
let development = process.env.NODE_ENV !== 'production'
export default {
  ssr: false,
  head: { title: 'front', htmlAttrs: { lang: 'en' },
    meta: [ { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: '' },
      { name: 'format-detection', content: 'telephone=no' }
    ], link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }]
  },
  css: ['@fortawesome/fontawesome-svg-core/styles.css','@/assets/scss/main.scss'],
  plugins: [ '~/plugins/fontawesome.js' ],
  components: true,
  buildModules: [],
  router: { middleware: ['auth'] },
  modules: ['@nuxtjs/axios', '@nuxtjs/auth'],
  axios: { baseURL: development ? 'http://localhost:3000' : 'https://ruxtmin-back.fly.dev/' },
  server: { port: development ? 3001 : 3000 },
  auth: {
    redirect: { login: '/' },
    strategies: {
      local: {
        endpoints: {
          login: { url: 'login', method: 'post', propertyName: 'data' },
          logout: false,
          user: { url: 'me', method: 'get', propertyName: 'data' }
        }
      }
    }
  }
}
~
EOF
cat <<'EOF' | puravida middleware/adminOnly.js ~
export default function ({ store, redirect }) {
  if (!store.state.auth.user.admin) {
    return redirect('/')
  }
}
~
EOF
cat <<'EOF' | puravida middleware/currentUserOrAdminOnly.js ~
import { mapGetters } from 'vuex'
export default function ({ route, store, redirect }) {
  const { isAdmin, loggedInUser } = store.getters
  const url = route.fullPath;
  const splitPath = url.split('/')
  let idParam = null;
  if (url.includes("edit")) {
    idParam = parseInt(splitPath[splitPath.length-2])
  } else {
    idParam = parseInt(splitPath[splitPath.length-1])
  }
  const isUserCurrentUser = idParam === loggedInUser.id
  if (!isAdmin && !isUserCurrentUser) {
    return redirect('/')
  }
}
~
EOF
cat <<'EOF' | puravida plugins/fontawesome.js ~
import Vue from 'vue'
import { library, config } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { fas } from '@fortawesome/free-solid-svg-icons'

config.autoAddCss = false
library.add(fas)
Vue.component('font-awesome-icon', FontAwesomeIcon)
~
EOF
rm -f components/*.vue
echo -e "\n\n🦄 New User Page\n\n"
cat <<'EOF' | puravida components/user/Form.vue ~
<template>
  <section>
    <h1 v-if="editNewOrSignup === 'edit'">Edit User</h1>
    <h1 v-else-if="editNewOrSignup === 'new'">Add User</h1>
    <h1 v-else-if="editNewOrSignup === 'sign-up'">Sign Up</h1>
    <article>
      <form enctype="multipart/form-data">
        <p v-if="editNewOrSignup === 'edit'">id: {{ $route.params.id }}</p>
        <p>Name: </p><input v-model="name">
        <p>Email: </p><input v-model="email">
        <p class="no-margin">Avatar: </p>
        <img v-if="!hideAvatar && editNewOrSignup === 'edit'" :src="avatar" />    
        <input type="file" ref="inputFile" @change=uploadAvatar()>
        <p v-if="editNewOrSignup !== 'edit'">Password: </p>
        <input v-if="editNewOrSignup !== 'edit'" type="password" v-model="password">
        <button v-if="editNewOrSignup !== 'edit'" @click.prevent=createUser>Create User</button>
        <button v-else-if="editNewOrSignup == 'edit'" @click.prevent=editUser>Edit User</button>
      </form>
    </article>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  data () {
    return {
      name: "",
      email: "",
      avatar: "",
      password: "",
      editNewOrSignup: "",
      hideAvatar: false
    }
  },
  mounted() {
    const splitPath = $nuxt.$route.path.split('/')
    this.editNewOrSignup = splitPath[splitPath.length-1]
  },
  computed: {
    ...mapGetters(['isAuthenticated', 'isAdmin', 'loggedInUser`']),
  },
  async fetch() {
    const splitPath = $nuxt.$route.path.split('/')
    this.editNewOrSignup = $nuxt.$route.path.split('/')[$nuxt.$route.path.split('/').length-1]
    if ($nuxt.$route.path.split('/')[$nuxt.$route.path.split('/').length-1]=='edit') {
      const user = await this.$axios.$get(`users/${this.$route.params.id}`)
      this.name = user.name
      this.email = user.email,
      this.avatar = user.avatar  
    }
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0]
      this.hideAvatar = true
    },
    createUser: function() {
      const params = {
        'name': this.name,
        'email': this.email,
        'avatar': this.avatar,
        'password': this.password,
      }
      let payload = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => payload.append(key, value)
      )
      this.$axios.$post('users', payload)
        .then(() => {
          this.$auth.loginWith('local', {
            data: {
            email: this.email,
            password: this.password
            },
          })
          .then(() => {
            const userId = this.$auth.$state.user.id
            this.$router.push(`/users/${userId}`)
          })
        })
    },
    editUser: function() {
      let params = {}
      const filePickerFile = this.$refs.inputFile.files[0]
      if (!filePickerFile) {
        params = { 'name': this.name, 'email': this.email }
      } else {
        params = { 'name': this.name, 'email': this.email, 'avatar': this.avatar }
      }
    
      let payload = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => payload.append(key, value)
      )
      this.$axios.$patch(`/users/${this.$route.params.id}`, payload)
        .then(() => {
          this.$router.push(`/users/${this.$route.params.id}`)
        })
    },
  }
}
</script>
~
EOF
cat <<'EOF' | puravida pages/users/new.vue ~
<template>
  <main class="container">
    <UserForm />
  </main>
</template>
~
EOF
echo -e "\n\n🦄 Users Page\n\n"
cat <<'EOF' | puravida components/user/Card.vue ~
<template>
  <article>
    <h2>
      <NuxtLink :to="`/users/${user.id}`">{{ user.name }}</NuxtLink> 
      <NuxtLink :to="`/users/${user.id}/edit`"><font-awesome-icon icon="pencil" /></NuxtLink>
      <a @click.prevent=deleteUser(user.id) href="#"><font-awesome-icon icon="trash" /></a>
    </h2>
    <p>id: {{ user.id }}</p>
    <p>email: {{ user.email }}</p>
    <p v-if="user.avatar !== null" class="no-margin">avatar:</p>
    <img v-if="user.avatar !== null" :src="user.avatar" />
    <p v-if="isAdmin">admin: {{ user.admin }}</p>
  </article>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  name: 'UserCard',
  computed: { ...mapGetters(['isAdmin']) },
  props: {
    user: {
      type: Object,
      default: () => ({}),
    },
    users: {
      type: Array,
      default: () => ([]),
    },
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0];
    },
    deleteUser: function(id) {
      this.$axios.$delete(`users/${id}`)
      const index = this.users.findIndex((i) => { return i.id === id })
      this.users.splice(index, 1);
    }
  }
}
</script>
~
EOF
cat <<'EOF' | puravida components/user/Set.vue ~
<template>
  <section>
    <div v-for="user in users" :key="user.id">
      <UserCard :user="user" :users="users" />
    </div>
  </section>
</template>

<script>
export default {
  data: () => ({
    users: []
  }),
  async fetch() {
    this.users = await this.$axios.$get('users')
  }
}
</script>
~
EOF

cat <<'EOF' | puravida pages/users/index.vue ~
<template>
  <main class="container">
    <h1>Users</h1>
    <NuxtLink to="/users/new" role="button">Add User</NuxtLink>
    <UserSet />
  </main>
</template>

<script>
export default { middleware: 'adminOnly' }
</script>
~
EOF

echo -e "\n\n🦄 User Page\n\n"
cat <<'EOF' | puravida pages/users/_id/index.vue ~
<template>
  <main class="container">
    <section>
      <UserCard :user="user" />
    </section>
  </main>
</template>

<script>
export default {
  middleware: 'currentUserOrAdminOnly',
  data: () => ({ user: {} }),
  async fetch() { this.user = await this.$axios.$get(`users/${this.$route.params.id}`) },
  methods: {
    uploadAvatar: function() { this.avatar = this.$refs.inputFile.files[0] },
    deleteUser: function(id) {
      this.$axios.$delete(`users/${this.$route.params.id}`)
      this.$router.push('/users')
    }
  }
}
</script>
~
EOF

echo -e "\n\n🦄 User Edit Page\n\n"
cat <<'EOF' | puravida pages/users/_id/edit.vue ~
<template>
  <main class="container">
    <UserForm />
  </main>
</template>

<script>
export default { middleware: 'currentUserOrAdminOnly' }
</script>
~
EOF

# echo -e "\n\n🦄 Widgets\n\n"
# cat <<'EOF' | puravida components/widget/Card.vue ~
# <template>
#   <article>
#     <h2>
#       <NuxtLink :to="`/widgets/${widget.id}`">{{ widget.name }}</NuxtLink> 
#       <NuxtLink :to="`/widgets/${widget.id}/edit`"><font-awesome-icon icon="pencil" /></NuxtLink>
#       <a @click.prevent=deleteWidget(widget.id) href="#"><font-awesome-icon icon="trash" /></a>
#     </h2>
#     <p>id: {{ widget.id }}</p>
#     <p>name: {{ widget.name }}</p>
#     <p>description: {{ widget.description }}</p>
#     <p>user: {{ widget.userId }}</p>
#     <p v-if="widget.image !== null" class="no-margin">image:</p>
#     <img v-if="widget.image !== null" :src="widget.image" />
#   </article>
# </template>

# <script>
# import { mapGetters } from 'vuex'
# export default {
#   computed: { ...mapGetters(['isAdmin']) },
#   props: {
#     widget: { type: Object, default: () => ({}) },
#     widgets: { type: Array, default: () => ([]) },
#   },
#   methods: {
#     uploadImage: function() {
#       this.image = this.$refs.inputFile.files[0];
#     },
#     deleteWidget: function(id) {
#       this.$axios.$delete(`widgets/${id}`)
#       const index = this.widgets.findIndex((i) => { return i.id === id })
#       this.widgets.splice(index, 1);
#       this.$router.push('/widgets')
#     }
#   }
# }
# </script>
# ~
# EOF
# cat <<'EOF' | puravida components/widget/Set.vue ~
# <template>
#   <section>
#     <div v-for="widget in userWidgets" :key="widget.id">
#       <WidgetCard :widget="widget" :widgets="widgets" />
#     </div>
#   </section>
# </template>

# <script>
# export default {
#   data: () => ({ userWidgets: [], allWidgets: [] }),
#   async fetch() { 
#     this.userWidgets = this.$store.getters.loggedInUser.widgets
#     this.allWidgets = await this.$axios.$get('widgets') 
#     // console.log(this.widgets)
#   }
# }
# </script>
# ~
# EOF

# cat <<'EOF' | puravida components/widget/Form.vue ~
# <template>
#   <article>
#     <h2>
#       <NuxtLink :to="`/widgets/${widget.id}`">{{ widget.name }}</NuxtLink> 
#       <NuxtLink :to="`/widgets/${widget.id}/edit`"><font-awesome-icon icon="pencil" /></NuxtLink>
#       <a @click.prevent=deleteWidget(widget.id) href="#"><font-awesome-icon icon="trash" /></a>
#     </h2>
#     <p>id: {{ widget.id }}</p>
#     <p>name: {{ widget.name }}</p>
#     <p>description: {{ widget.description }}</p>
#     <p>user: <NuxtLink :to="`/users/${widget.userId}`">{{ widget.userName }}</NuxtLink></p>
#     <p v-if="widget.image !== null" class="no-margin">image:</p>
#     <img v-if="widget.image !== null" :src="widget.image" />
#   </article>
# </template>

# <script>
# import { mapGetters } from 'vuex'
# export default {
#   computed: { ...mapGetters(['isAdmin']) },
#   props: {
#     widget: { type: Object, default: () => ({}) },
#     widgets: { type: Array, default: () => ([]) },
#   },
#   methods: {
#     uploadImage: function() {
#       this.image = this.$refs.inputFile.files[0];
#     },
#     deleteWidget: function(id) {
#       this.$axios.$delete(`widgets/${id}`)
#       const index = this.widgets.findIndex((i) => { return i.id === id })
#       this.widgets.splice(index, 1);
#     }
#   }
# }
# </script>
# ~
# EOF


# cat <<'EOF' | puravida pages/widgets/index.vue ~
# <template>
#   <main class="container">
#     <h1>Widgets</h1>
#     <NuxtLink to="/widgets/new" role="button">Add Widget</NuxtLink>
#     <WidgetSet />
#   </main>
# </template>
# ~
# EOF

# cat <<'EOF' | puravida pages/widgets/new.vue ~
# <template>
#   <main class="container">
#     <WidgetForm />
#   </main>
# </template>
# ~
# EOF

# cat <<'EOF' | puravida pages/widgets/_id/index.vue ~
# <template>
#   <main class="container">
#     <section>
#       <WidgetCard :widget="widget" />
#     </section>
#   </main>
# </template>

# <script>
# export default {
#   middleware: 'currentUserOrAdminOnly',
#   data: () => ({ widget: {} }),
#   async fetch() { this.widget = await this.$axios.$get(`widgets/${this.$route.params.id}`) },
#   methods: {
#     uploadImage: function() { this.image = this.$refs.inputFile.files[0]; },
#     deleteWidget: function(id) {
#       this.$axios.$delete(`widgets/${this.$route.params.id}`)
#       this.$router.push('/widgets')
#     }
#   }
# }
# </script>
# ~
# EOF

# cat <<'EOF' | puravida pages/widgets/_id/edit.vue ~
# <template>
#   <main class="container">
#     <WidgetForm />
#   </main>
# </template>

# <script>
# export default { middleware: 'currentUserOrAdminOnly' }
# </script>
# ~
# EOF


echo -e "\n\n🦄 Nav\n\n"
cat <<'EOF' | puravida components/nav/Brand.vue ~
<template>
  <span>
    <font-awesome-icon icon="laptop-code" /> Ruxtmin
  </span>
</template>
~
EOF
cat <<'EOF' | puravida components/nav/Default.vue ~
<template>
  <nav class="top-nav container-fluid">
    <ul><li><strong><NuxtLink to="/"><NavBrand /></NuxtLink></strong></li></ul>
    <input id="menu-toggle" type="checkbox" />
    <label class='menu-button-container' for="menu-toggle">
      <div class='menu-button'></div>
    </label>
    <ul class="menu">
      <li v-if="!isAuthenticated"><strong><NuxtLink to="/log-in">Log In</NuxtLink></strong></li>
      <li v-if="!isAuthenticated"><strong><NuxtLink to="/sign-up">Sign Up</NuxtLink></strong></li>
      <li v-if="isAuthenticated"><strong><NuxtLink to="/widgets">Widgets</NuxtLink></strong></li>
      <li v-if="isAdmin"><strong><NuxtLink to="/admin">Admin</NuxtLink></strong></li>
      <li v-if="isAuthenticated" class='dropdown'>
        <details role="list" dir="rtl">
          <summary class='summary' aria-haspopup="listbox" role="link">
            <img v-if="loggedInUser.avatar" :src="loggedInUser.avatar" />
            <font-awesome-icon v-else icon="circle-user" />
          </summary>
          <ul role="listbox">
            <li><NuxtLink :to="`/users/${loggedInUser.id}`">Profile</NuxtLink></li>
            <li><NuxtLink :to="`/users/${loggedInUser.id}/edit`">Settings</NuxtLink></li>
            <li><a @click="logOut">Log Out</a></li>
          </ul>
        </details>
      </li>
      <!-- <li v-if="isAuthenticated"><strong><NuxtLink :to="`/users/${loggedInUser.id}`">Settings</NuxtLink></strong></li> -->
      <li class="logout-desktop" v-if="isAuthenticated"><strong><a @click="logOut">Log Out</a></strong></li>
    </ul>
  </nav>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  computed: { ...mapGetters(['isAuthenticated', 'isAdmin', 'loggedInUser']) }, 
  methods: { logOut() { this.$auth.logout() } }
}
</script>

<style lang="sass" scoped>
// css-only responsive nav
// from https://codepen.io/alvarotrigo/pen/MWEJEWG (accessed 10/16/23, modified slightly)

h2 
  vertical-align: center
  text-align: center

html, body 
  margin: 0
  height: 100%

.top-nav 
  // display: flex
  // flex-direction: row
  // align-items: center
  // justify-content: space-between
  // background-color: #00BAF0
  // background: linear-gradient(to left, #f46b45, #eea849)
  /* W3C, IE 10+/ Edge, Firefox 16+, Chrome 26+, Opera 12+, Safari 7+ */
  // color: #FFF
  height: 50px
  // padding: 1em

.top-nav > ul 
  margin-top: 15px

.menu 
  display: flex
  flex-direction: row
  list-style-type: none
  margin: 0
  padding: 0

[type="checkbox"] ~ label.menu-button-container 
  display: none
  height: 100%
  width: 30px
  cursor: pointer
  flex-direction: column
  justify-content: center
  align-items: center

#menu-toggle 
  display: none

.menu-button,
.menu-button::before,
.menu-button::after 
  display: block
  background-color: #000
  position: absolute
  height: 4px
  width: 30px
  transition: transform 400ms cubic-bezier(0.23, 1, 0.32, 1)
  border-radius: 2px

.menu-button::before 
  content: ''
  margin-top: -8px

.menu-button::after 
  content: ''
  margin-top: 8px

#menu-toggle:checked + .menu-button-container .menu-button::before 
  margin-top: 0px
  transform: rotate(405deg)

#menu-toggle:checked + .menu-button-container .menu-button 
  background: rgba(255, 255, 255, 0)

#menu-toggle:checked + .menu-button-container .menu-button::after 
  margin-top: 0px
  transform: rotate(-405deg)

.menu 
  > li 
    overflow: visible

  > li.dropdown
    background: none

    .summary
      margin: 0
      padding: 1rem 0
      font-size: 1.5rem

      &:focus
        color: var(--color)
        background: none

      &:after
        display: none

    ul
      padding-top: 0
      margin-top: 0
      right: -1rem

  > li.logout-desktop
    display: none

@media (max-width: 991px) 
  .menu 
    
    > li 
      overflow: hidden
    
    > li.dropdown
      display: none

    > li.logout-desktop
      display: flex

  [type="checkbox"] ~ label.menu-button-container 
    display: flex

  .top-nav > ul.menu 
    position: absolute
    top: 0
    margin-top: 50px
    left: 0
    flex-direction: column
    width: 100%
    justify-content: center
    align-items: center

  #menu-toggle ~ .menu li 
    height: 0
    margin: 0
    padding: 0
    border: 0
    transition: height 400ms cubic-bezier(0.23, 1, 0.32, 1)

  #menu-toggle:checked ~ .menu li 
    border: 1px solid #333
    height: 2.5em
    padding: 0.5em
    transition: height 400ms cubic-bezier(0.23, 1, 0.32, 1)

  .menu > li 
    display: flex
    justify-content: center
    margin: 0
    padding: 0.5em 0
    width: 100%
    // color: white
    background-color: #222

  .menu > li:not(:last-child) 
    border-bottom: 1px solid #444
</style>
~
EOF
cat <<'EOF' | puravida layouts/default.vue ~
<template>
  <div>
    <NavDefault />
    <Nuxt />
  </div>
</template>
~
EOF
echo -e "\n\n🦄 Home\n\n"
cat <<'EOF' | puravida pages/index.vue ~
<template>
  <main class="container">
    <h1>Rails 7 Nuxt 2 Admin Boilerplate</h1>
    
    <h2 class="small-bottom-margin">Features</h2>
    <ul class="features">
      <li>Admin dashboard</li>
      <li>Placeholder users</li>
      <li>Placeholder user item ("widget")</li>
    </ul>

    <h3 class="small-bottom-margin stack">Stack</h3>
    <div class="aligned-columns">
      <p><span>frontend:</span> Nuxt 2</p>
      <p><span>backend API:</span> Rails 7</p>
      <p><span>database:</span> Postgres</p>
      <p><span>styles:</span> Sass</p>
      <p><span>css framework:</span> Pico.css</p>
      <p><span>e2e tests:</span> Cypress</p>
      <p><span>api tests:</span> RSpec</p>
    </div>

    <h3 class="small-bottom-margin tools">Tools</h3>
    <div class="aligned-columns">
      <p><span>user avatars:</span> local active storage</p>
      <p><span>backend auth:</span> bcrypt & jwt</p>
      <p><span>frontend auth:</span> nuxt auth module</p>
    </div>

    <h3 class="small-bottom-margin">User Logins</h3>
    <table class="half-width">
      <tr><th>Email</th><th>Password</th><th>Notes</th></tr>
      <tr><td>michaelscott@dundermifflin.com</td><td>password</td><td>(admin)</td></tr>
      <tr><td>jimhalpert@dundermifflin.com</td><td>password</td><td></td></tr>
      <tr><td>pambeesly@dundermifflin.com</td><td>password</td><td></td></tr>
    </table>
    
    <p class="big-bottom-margin">
      <NuxtLink to="/log-in" role="button" class="secondary">Log In</NuxtLink> 
      <NuxtLink to="/sign-up" role="button" class="contrast outline">Sign Up</NuxtLink>
    </p>    

  </main>
</template>

<script>
export default { auth: false }
</script>
~
EOF
cat <<'EOF' | puravida components/Notification.vue ~
<template>
  <div class="notification is-danger">
    {{ message }}
  </div>
</template>

<script>
export default {
  name: 'Notification',
  props: ['message']
}
</script>
~
EOF

echo -e "\n\n🦄 Login & Signup Pages\n\n"
cat <<'EOF' | puravida pages/log-in.vue ~
<template>
  <main class="container">
    <h2>Log In</h2>
    <Notification :message="error" v-if="error"/>
    <form method="post" @submit.prevent="login">
      <div>
        <label>Email</label>
        <div>
          <input
            type="email"
            name="email"
            v-model="email"
          />
        </div>
      </div>
      <div>
        <label>Password</label>
        <div>
          <input
            type="password"
            name="password"
            v-model="password"
          />
        </div>
      </div>
      <div>
        <button type="submit">Log In</button>
      </div>
    </form>
    <div>
      <p>
        Don't have an account? <NuxtLink to="/sign-up">Sign up</NuxtLink>
      </p>
    </div>
  </main>
</template>

<script>
import Notification from '~/components/Notification'
export default {
  auth: false,
  components: {
    Notification,
  },
  data() {
    return {
      email: '',
      password: '',
      error: null
    }
  },
  methods: {
    async login() {
      this.$auth.loginWith('local', {
        data: {
          email: this.email,
          password: this.password
        }
      }).then (() => {
        const id = this.$auth.$state.user.id
        this.$router.push(`/users/${id}`)
      })
    }
  }
}
</script>
~
EOF
cat <<'EOF' | puravida pages/sign-up.vue ~
<template>
  <main class="container">
    <UserForm />      
  </main>
</template>

<script>
export default { auth: false }
</script>
~
EOF
cat <<'EOF' | puravida store/index.js ~
export const getters = {
  isAuthenticated(state) {
    return state.auth.loggedIn
  },

  isAdmin(state) {
    if (state.auth.user && state.auth.user.admin !== null && state.auth.user.admin == true) { 
        return true
    } else {
      return false
    } 
  },

  loggedInUser(state) {
    return state.auth.user
  }
}
~
EOF

echo -e "\n\n🦄 Admin Page\n\n"

cat <<'EOF' | puravida pages/admin/index.vue ~
<template>
  <main class="container">
    <h1>Admin</h1>
    <p>Number of users: {{ this.users.length }}</p>
    <p>Number of admins: {{ (this.users.filter((obj) => obj.admin === true)).length }}</p>
    <p><NuxtLink to="/users">Users</NuxtLink></p>
    <p><NuxtLink to="/admin/widgets">Widgets</NuxtLink></p>
  </main>
</template>

<script>
export default { 
  middleware: 'adminOnly',
  layout: 'admin',
  data: () => ({ users: [] }),
  async fetch() { this.users = await this.$axios.$get('users') }
}
</script>
~
EOF

cat <<'EOF' | puravida pages/admin/users.vue ~
<template>
  <main class="container">
    <h1>Users</h1>
    <NuxtLink to="/users/new" role="button">Add User</NuxtLink>
    <UserSet />
  </main>
</template>

<script>
export default {
  middleware: 'adminOnly'
}
</script>
~
EOF
# cat <<'EOF' | puravida pages/admin/widgets.vue ~
# <template>
#   <main class="container">
#     <h1>Widgets</h1>
#     <NuxtLink to="/users/new" role="button">Add Widgets</NuxtLink>
#     <WidgetSet />
#   </main>
# </template>

# <script>
# export default {
#   middleware: 'adminOnly'
# }
# </script>
# ~
# EOF


echo -e "\n\n🦄 Cypress\n\n"
cd ~/Desktop/front
npm install cypress --save-dev
npx cypress open
rails db:drop db:create db:migrate db:seed RAILS_ENV=test
puravida cypress/fixtures/images
cp -a ~/Desktop/ruxtmin/assets/images/office-avatars ~/Desktop/front/cypress/fixtures/images

cat <<'EOF' | puravida cypress/support/commands.js ~
Cypress.Commands.add('login', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('jimhalpert@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginNonAdmin', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('jimhalpert@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginAdmin', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('michaelscott@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginInvalid', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('xyz@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('logoutNonAdmin', (admin) => { 
  cy.logout(false);
})

Cypress.Commands.add('logoutAdmin', (admin) => { 
  cy.logout(true);
})

Cypress.Commands.add('logout', (admin) => { 
  const num = admin ? 2 : 1
  cy.get('nav ul.menu').find('li').eq(num).click()
    .then(() => { cy.get('nav details ul').find('li').eq(2).click() })
})
~
EOF
cat <<'EOF' | puravida cypress/e2e/logged-out-page-copy.cy.js ~
/// <reference types="cypress" />

// reset the db: db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000
context('Logged Out', () => {
  describe('Homepage Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/')
      cy.get('main.container')
        .should('contain', 'Rails 7 Nuxt 2 Admin Boilerplate')
        .should('contain', 'Features')
      cy.get('ul.features')
        .within(() => {
          cy.get('li').eq(0).contains('Admin dashboard')
          cy.get('li').eq(1).contains('Placeholder users')
          cy.get('li').eq(2).contains('Placeholder user item ("widget")')
        })
      cy.get('h3.stack')
        .next('div.aligned-columns')
          .within(() => {
            cy.get('p').eq(0).contains('frontend:')
            cy.get('p').eq(0).contains('Nuxt 2')
            cy.get('p').eq(1).contains('backend API:')
            cy.get('p').eq(1).contains('Rails 7')
            cy.get('p').eq(2).contains('database:')
            cy.get('p').eq(2).contains('Postgres')
            cy.get('p').eq(3).contains('styles:')
            cy.get('p').eq(3).contains('Sass')
            cy.get('p').eq(4).contains('css framework:')
            cy.get('p').eq(4).contains('Pico.css')
            cy.get('p').eq(5).contains('e2e tests:')
            cy.get('p').eq(5).contains('Cypress')
            cy.get('p').eq(6).contains('api tests:')
            cy.get('p').eq(6).contains('RSpec')      
          })
      cy.get('h3.tools')
        .next('div.aligned-columns')
          .within(() => {
            cy.get('p').eq(0).contains('user avatars:')
            cy.get('p').eq(0).contains('local active storage')
            cy.get('p').eq(1).contains('backend auth:')
            cy.get('p').eq(1).contains('bcrypt & jwt')
            cy.get('p').eq(2).contains('frontend auth:')
            cy.get('p').eq(2).contains('nuxt auth module')
          }) 
    })
  })

  describe('Log In Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.get('main.container')
        .should('contain', 'Email')
        .should('contain', 'Password')
        .should('contain', 'Log In')
        .should('contain', "Don't have an account")
    })
  })

  describe('Sign Up Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/sign-up')
      cy.get('main.container')
        .should('contain', 'Name')
        .should('contain', 'Email')
        .should('contain', 'Avatar')
        .should('contain', 'Password')
        .should('contain', 'Create User')
    })
  })
})
~
EOF
cat <<'EOF' | puravida cypress/e2e/sign-up-flow.cy.js ~
/// <reference types="cypress" />

// reset the db: db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000
describe('Sign Up Flow', () => {
  it('Should redirect to user show page', () => {
    cy.visit('http://localhost:3001/sign-up')
    cy.get('p').contains('Name').next('input').type('name')
    cy.get('p').contains('Email').next('input').type('test' + Math.random().toString(36).substring(2, 15) + '@mail.com')
    cy.get('p').contains('Email').next('input').type('test' + Math.random().toString(36).substring(2, 15) + '@mail.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/dwight-schrute.png')
    cy.get('p').contains('Password').next('input').type('password')
    cy.get('button').contains('Create User').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/\d+/)
    cy.get('h2').should('contain', 'name')
    // TODO: assert avatar presence
    // cy.logout()
  })
})
~
EOF
cat <<'EOF' | puravida cypress/e2e/log-in-flow.cy.js ~
/// <reference types="cypress" />

// reset the db: db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000

describe('Manual Login', () => {
  it('Should log in user', () => {
    cy.intercept('POST', '/login').as('login')
    cy.loginAdmin()
    cy.wait('@login').then(({response}) => {
      expect(response.statusCode).to.eq(200)
    })
    cy.url().should('eq', 'http://localhost:3001/users/1')
    cy.get('h2').should('contain', 'Michael Scott')
    cy.logoutAdmin()
  })
})

context('Mocked Request Login', () => {
  describe('Login with real email', () => {
    it('Should get 200 response', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.request(
        { url: 'http://localhost:3000/login', method: 'POST', body: { email: 'michaelscott@dundermifflin.com', 
        password: 'password' }, failOnStatusCode: false })
        .its('status').should('equal', 200)
      cy.get('h2').should('contain', 'Log In')
      cy.url().should('include', '/log-in')
    })
  })

  describe('Login with fake email', () => {
    it('Should get 401 response', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.request(
        { url: 'http://localhost:3000/login', method: 'POST', body: { email: 'xyz@dundermifflin.com', 
        password: 'password' }, failOnStatusCode: false })
        .its('status').should('equal', 401)
      cy.get('h2').should('contain', 'Log In')
      cy.url().should('include', '/log-in')
    })
  })
})
~
EOF
cat <<'EOF' | puravida cypress/e2e/admin.cy.js ~
/// <reference types="cypress" />

// reset the db: rails db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000

describe('Admin login', () => {
  it('Should go to admin show page', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.get('h2').should('contain', 'Michael Scott')
    cy.get('p').should('contain', 'id: 1')
    cy.get('p').should('contain', 'avatar:')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*michael-scott.png/)
    cy.get('p').should('contain', 'admin: true')
    cy.logoutAdmin()
  })
  it('Should contain admin nav', () => {
    cy.loginAdmin()
    cy.get('nav ul.menu li a').should('contain', 'Admin')
    cy.logoutAdmin()
  })
})

describe('Admin nav', () => {
  it('Should work', () => {
    cy.loginAdmin()
    cy.get('nav li a').contains('Admin').click()
    cy.url().should('match', /http:\/\/localhost:3001\/admin/)
    cy.logoutAdmin()
  })
})

describe('Admin page', () => {
  it('Should have correct copy', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.visit('http://localhost:3001/admin')
    cy.url().should('match', /http:\/\/localhost:3001\/admin/)
    cy.get('p').eq(0).invoke('text').should('match', /Number of users: \d+/)
    cy.get('p').eq(1).invoke('text').should('match', /Number of admins: \d+/)
    cy.get('p').eq(2).contains('Users')
    cy.get('p').eq(3).contains('Widgets')
    cy.logoutAdmin()
  })
  it('Should have correct links', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.visit('http://localhost:3001/admin')
    cy.url().should('match', /http:\/\/localhost:3001\/admin/)
    cy.get('p').contains('Users').should('have.attr', 'href', '/users')
    cy.logoutAdmin()
  })
  it('Should have working links', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.visit('http://localhost:3001/admin')
    cy.url().should('match', /http:\/\/localhost:3001\/admin/)
    cy.get('p a').contains('Users').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users/)
    cy.logoutAdmin()
  })
})

describe('Edit user as admin', () => {
  it('Should be successful', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.get('h2').children().eq(1).click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('name')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('name@mail.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/dwight-schrute.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.get('h2').should('contain', 'name')
    cy.get('p').contains('email').should('contain', 'name@mail.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*dwight-schrute.png/)
    cy.get('p').should('contain', 'admin: true')
    cy.get('h2').children().eq(1).click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('Michael Scott')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('michaelscott@dundermifflin.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/michael-scott.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.get('h2').should('contain', 'Michael Scott')
    cy.get('p').contains('email').should('contain', 'michaelscott@dundermifflin.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*michael-scott.png/)
    cy.get('p').should('contain', 'admin: true')
    cy.logoutAdmin()
  })
})

describe('Admin /users page', () => {
  it('Should show three users', () => {
    cy.loginAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/1/)
    cy.visit('http://localhost:3001/users')
    cy.url().should('match', /http:\/\/localhost:3001\/users/)
    cy.get('section').children('div').should('have.length', 3)
    cy.logoutAdmin()
  })
})
~
EOF
cat <<'EOF' | puravida cypress/e2e/non-admin.cy.js ~
/// <reference types="cypress" />

// reset the db: rails db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000

describe('Non-admin login', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'Jim Halpert')
    cy.get('p').should('contain', 'id: 2')
    cy.get('p').should('contain', 'avatar:')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*jim-halpert.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.logoutNonAdmin()
  })
  it('Should not contain admin nav', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('nav ul.menu li a').contains('Admin').should('not.exist')
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users as non-admin', () => {
  it('Should redirect to home', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/1 as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/1', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/2 as non-admin user 2', () => {
  it('Should go to user show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/2', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/users\/2$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/3 as non-admin user 2', () => {
  it('Should go to home', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/3', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/1/edit as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/1/edit', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/3/edit as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/3/edit', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Edit self as non-admin', () => {
  it('Edit should be successful', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').contains('Jim Halpert').next('a').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('name')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('name@mail.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/dwight-schrute.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'name')
    cy.get('p').contains('email').should('contain', 'name@mail.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*dwight-schrute.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.get('h2').children().eq(1).click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('Jim Halpert')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('jimhalpert@dundermifflin.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/jim-halpert.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'Jim Halpert')
    cy.get('p').contains('email').should('contain', 'jimhalpert@dundermifflin.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*jim-halpert.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.logoutNonAdmin()
  })
})
~
EOF


# echo -e "\n\n🦄 Deploy\n\n"

# cd ~/Desktop/back
# cat <<'EOF' | puravida fly.toml ~
# app = "ruxtmin-back"
# primary_region = "dfw"
# console_command = "/rails/bin/rails console"

# [build]

# [env]
#   RAILS_STORAGE = "/data"

# [[mounts]]
#   source = "ruxtmin_data"
#   destination = "/data"

# [http_service]
#   internal_port = 3000
#   force_https = true
#   auto_stop_machines = false
#   auto_start_machines = true
#   min_machines_running = 0
#   processes = ["app"]

# [[statics]]
#   guest_path = "/rails/public"
#   url_prefix = "/"
# ~
# puravida config/storage.yml ~
# test:
#   service: Disk
#   root: <%= Rails.root.join("tmp/storage") %>

# local:
#   service: Disk
#   root: <%= Rails.root.join("storage") %>

# production:
#   service: Disk
#   root: /data
# ~
# EOF
# cat <<'EOF' | puravida config/environmnets/production.rb ~
# require "active_support/core_ext/integer/time"
# Rails.application.configure do
#   config.cache_classes = true
#   config.eager_load = true
#   config.consider_all_requests_local       = false
#   config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
#   config.active_storage.service = :production
#   config.log_level = :info
#   config.log_tags = [ :request_id ]
#   config.action_mailer.perform_caching = false
#   config.i18n.fallbacks = true
#   config.active_support.report_deprecations = false
#   config.log_formatter = ::Logger::Formatter.new
#   if ENV["RAILS_LOG_TO_STDOUT"].present?
#     logger           = ActiveSupport::Logger.new(STDOUT)
#     logger.formatter = config.log_formatter
#     config.logger    = ActiveSupport::TaggedLogging.new(logger)
#   end
#   config.active_record.dump_schema_after_migration = false
# end
# ~
# EOF
# fly launch --copy-config --name ruxtmin-back --region dfw --yes
# fly deploy
# cd ~/Desktop/front
# npm run build
# fly launch --name ruxtmin-front --region dfw --yes
# fly deploy


# echo -e "\n\n🦄 DON'T FORGET TO SEED THE PROD USERS IN THE BACKEND!!!\n\n"

# echo -e "\n\n🦄 Have a nice day!\n\n"