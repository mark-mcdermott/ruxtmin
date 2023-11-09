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