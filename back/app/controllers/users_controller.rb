class UsersController < ApplicationController
  skip_before_action :require_login, only: :create
  
  def index
    @users = User.all.map do |u|
      avatar = u.avatar.present? ? url_for(u.avatar) : nil
      { :id => u.id, :name => u.name, :email => u.email, :avatar => avatar, :admin => u.admin }
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

  def update
    @user = User.find(params[:id])
    if @user.update(admin_params)
      render json: @user, status: 200
    else
      json render: @user, status: 400
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.avatar.purge
    @user.destroy
    render json: { status: 200, message: "user deleted successfully" }
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
      :id,
      :name,
      :email,
      :avatar,
      :admin,
      :password
    )
  end
end
