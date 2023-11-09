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