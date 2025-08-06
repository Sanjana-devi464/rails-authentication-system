class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [:show, :update, :destroy, :publish, :unpublish]

  def index
    @posts = Post.published.includes(:user).order(created_at: :desc)
    @posts = @posts.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @posts.as_json(include: { user: { only: [:id, :username, :first_name, :last_name] } })
  end

  def show
    render json: @post.as_json(include: { user: { only: [:id, :username, :first_name, :last_name] } })
  end

  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      render_success(@post, "Post created successfully")
    else
      render_error(@post.errors.full_messages.join(", "))
    end
  end

  def update
    if @post.update(post_params)
      render_success(@post, "Post updated successfully")
    else
      render_error(@post.errors.full_messages.join(", "))
    end
  end

  def destroy
    @post.destroy
    render_success({}, "Post deleted successfully")
  end

  def publish
    @post.update(status: :published)
    render_success(@post, "Post published successfully")
  end

  def unpublish
    @post.update(status: :draft)
    render_success(@post, "Post unpublished successfully")
  end

  def my_posts
    @posts = current_user.posts.includes(:user).order(created_at: :desc)
    @posts = @posts.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @posts.as_json(include: { user: { only: [:id, :username, :first_name, :last_name] } })
  end

  def search
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

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :status)
  end
end
