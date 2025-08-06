class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :activities, :notifications, :posts]

  def index
    @users = User.active.includes(:profile)
    @users = @users.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @users.as_json(
      only: [:id, :username, :first_name, :last_name, :email, :created_at],
      include: { profile: { only: [:bio, :location, :occupation] } }
    )
  end

  def show
    render json: @user.as_json(
      only: [:id, :username, :first_name, :last_name, :email, :created_at],
      include: { profile: { only: [:bio, :location, :occupation, :skills, :interests] } }
    )
  end

  def activities
    @activities = @user.user_activities.order(created_at: :desc)
    @activities = @activities.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @activities
  end

  def notifications
    @notifications = @user.notifications.order(created_at: :desc)
    @notifications = @notifications.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @notifications
  end

  def posts
    @posts = @user.posts.published.order(created_at: :desc)
    @posts = @posts.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @posts.as_json(include: { user: { only: [:id, :username, :first_name, :last_name] } })
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
