class Api::V1::SearchController < Api::V1::BaseController
  def users
    query = params[:q]
    
    if query.present?
      @users = User.active
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR username ILIKE ? OR email ILIKE ?", 
                         "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
                   .includes(:profile)
                   .page(params[:page]).per(params[:per_page] || 20)
    else
      @users = User.none
    end
    
    render json: @users.as_json(
      only: [:id, :username, :first_name, :last_name, :email],
      include: { profile: { only: [:bio, :location, :occupation] } }
    )
  end

  def posts
    query = params[:q]
    
    if query.present?
      @posts = Post.published
                   .where("title ILIKE ? OR body ILIKE ?", "%#{query}%", "%#{query}%")
                   .includes(:user)
                   .order(created_at: :desc)
                   .page(params[:page]).per(params[:per_page] || 20)
    else
      @posts = Post.none
    end
    
    render json: @posts.as_json(include: { user: { only: [:id, :username, :first_name, :last_name] } })
  end

  def global
    query = params[:q]
    
    if query.present?
      @users = User.active
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR username ILIKE ?", 
                         "%#{query}%", "%#{query}%", "%#{query}%")
                   .limit(10)
      
      @posts = Post.published
                   .where("title ILIKE ? OR body ILIKE ?", "%#{query}%", "%#{query}%")
                   .includes(:user)
                   .limit(10)
      
      render json: {
        users: @users.as_json(only: [:id, :username, :first_name, :last_name]),
        posts: @posts.as_json(
          only: [:id, :title, :created_at],
          include: { user: { only: [:username, :first_name, :last_name] } }
        )
      }
    else
      render json: { users: [], posts: [] }
    end
  end
end
