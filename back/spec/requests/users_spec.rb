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