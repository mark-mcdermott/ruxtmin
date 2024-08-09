class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
    render json: @users
  end

  # GET /users/1 or /users/1.json
  def show
    render json: @user.as_json.merge(avatar_url: @user.avatar.attached? ? url_for(@user.avatar) : nil)
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1 or /users/1.json

  def update
    if @user.update(user_params)
      render json: @user.as_json.merge(avatar_url: @user.avatar.attached? ? url_for(@user.avatar) : nil)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by!(uuid: params[:uuid])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:uuid, :email, :avatar, :password)
    end
end