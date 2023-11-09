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