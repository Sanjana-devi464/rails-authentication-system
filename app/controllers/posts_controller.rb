class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :simple_test, :test_simple]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :publish, :unpublish, :confirm_delete]
  before_action :check_owner, only: [:edit, :update, :destroy, :publish, :unpublish, :confirm_delete]
  before_action :track_user_activity, except: [:simple_test, :test_simple]

  # GET /posts
  def index
    # Start with published posts
    @posts = Post.published.includes(:user, :comments)
    
    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @posts = @posts.where("title ILIKE ? OR body ILIKE ?", search_term, search_term)
    end
    
    # Apply author filter
    if params[:author].present?
      @posts = @posts.where(user_id: params[:author])
    end
    
    # Apply time range filter
    if params[:time_range].present?
      case params[:time_range]
      when '1.day'
        @posts = @posts.where(created_at: 1.day.ago..Time.current)
      when '1.week'
        @posts = @posts.where(created_at: 1.week.ago..Time.current)
      when '1.month'
        @posts = @posts.where(created_at: 1.month.ago..Time.current)
      when '3.months'
        @posts = @posts.where(created_at: 3.months.ago..Time.current)
      when '1.year'
        @posts = @posts.where(created_at: 1.year.ago..Time.current)
      end
    end
    
    # Apply sorting
    case params[:sort]
    when 'created_at asc'
      @posts = @posts.order(created_at: :asc)
    when 'title asc'
      @posts = @posts.order(title: :asc)
    when 'title desc'
      @posts = @posts.order(title: :desc)
    when 'comments_count desc'
      @posts = @posts.left_joins(:comments).group(:id).order('COUNT(comments.id) DESC')
    else
      @posts = @posts.order(created_at: :desc) # Default: latest first
    end
    
    # Ransack for advanced search (keeping existing functionality)
    @q = Post.published.ransack(params[:q])
    
    # Pagination
    @posts = @posts.page(params[:page]).per(12)
    
    # Add meta tags for SEO
    set_meta_tags(
      title: 'All Posts',
      description: 'Browse all published posts from our community',
      keywords: 'blog, posts, articles, community'
    )
    
    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  # GET /posts/my-posts
  def my_posts
    @q = current_user.posts.ransack(params[:q])
    @posts = @q.result(distinct: true)
               .page(params[:page])
               .per(10)
    
    @draft_count = current_user.posts.drafts.count
    @published_count = current_user.posts.published.count
    @total_count = current_user.posts.count
    
    set_meta_tags(
      title: 'My Posts',
      description: 'Manage your blog posts and drafts'
    )
  end

  # GET /posts/my-first-blog
  def show
    # Check if user can view this post
    unless @post.can_be_viewed_by?(current_user)
      redirect_to posts_path, alert: 'Post not found or not accessible.'
      return
    end

    # Track view activity for published posts
    if @post.published? && current_user && current_user != @post.user
      UserActivity.create(
        user: current_user,
        activity_type: :feature_used,
        trackable: @post,
        description: "Viewed post: #{@post.title}"
      )
    end

    # SEO meta tags
    set_meta_tags(
      title: @post.title,
      description: @post.excerpt(160),
      keywords: "blog, post, #{@post.title.downcase}",
      author: @post.user.email,
      published_time: @post.created_at.iso8601,
      modified_time: @post.updated_at.iso8601
    )

    respond_to do |format|
      format.html
      format.json { render json: @post.as_json(include: :user) }
    end
  end

  # GET /posts/new
  def new
    @post = current_user.posts.build
    
    set_meta_tags(
      title: 'Create New Post',
      description: 'Write and publish a new blog post'
    )
  end

  # GET /posts/my-first-blog/edit
  def edit
    set_meta_tags(
      title: "Edit: #{@post.title}",
      description: 'Edit your blog post'
    )
  end

  # POST /posts
  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        # Track creation activity (handled by model callback)
        
        format.html do
          if @post.published?
            redirect_to @post, notice: 'Post was successfully created and published!'
          else
            redirect_to @post, notice: 'Post was successfully saved as draft!'
          end
        end
        format.json { render json: @post, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/my-first-blog
  def update
    old_status = @post.status
    
    respond_to do |format|
      if @post.update(post_params)
        # Track status change activity (handled by model callback)
        
        success_message = if old_status != @post.status
          case @post.status
          when 'published'
            'Post was successfully updated and published!'
          when 'draft'
            'Post was successfully updated and saved as draft!'
          end
        else
          'Post was successfully updated!'
        end
        
        format.html { redirect_to @post, notice: success_message }
        format.json { render json: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/my-first-blog
  def destroy
    post_title = @post.title
    
    @post.destroy
    
    # Track deletion activity (handled by model callback)
    
    respond_to do |format|
      format.html { redirect_to my_posts_posts_path, notice: "Post '#{post_title}' was successfully deleted!" }
      format.json { head :no_content }
    end
  end

  # POST /posts/my-first-blog/publish
  def publish
    if @post.update(status: :published)
      redirect_to @post, notice: 'Post was successfully published!'
    else
      redirect_to @post, alert: 'Failed to publish post.'
    end
  end

  # POST /posts/my-first-blog/unpublish  
  # GET /posts/my-first-blog/unpublish (temporary fallback)
  def unpublish
    # Handle both GET and POST requests - mostly for troubleshooting
    # In production, this should only be POST
    
    if @post.update(status: :draft)
      respond_to do |format|
        format.html { redirect_to @post, notice: 'Post was moved to drafts.' }
        format.json { render json: { status: 'success', message: 'Post unpublished' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @post, alert: 'Failed to unpublish post.' }
        format.json { render json: { status: 'error', message: 'Failed to unpublish post' } }
      end
    end
  end

  # GET /posts/my-first-blog/confirm_delete
  def confirm_delete
    # This action will render a confirmation page for deleting the post
  end

  # GET /posts/search
  def search
    @query = params[:q]
    @posts = Post.published.search(@query)
                 .includes(:user)
                 .page(params[:page])
                 .per(10)
    
    set_meta_tags(
      title: "Search Results: #{@query}",
      description: "Search results for '#{@query}'"
    )
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @posts }
    end
  end

  private

  def set_post
    @post = Post.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: 'Post not found.'
  end

  # Simple test action for debugging Trix editor
  def simple_test
    @post = Post.new
    render 'simple_test', layout: 'application'
  end

  # Another test action for debugging Trix editor
  def test_simple  
    @post = Post.new
    render 'test_simple', layout: 'application'
  end

  private

  def check_owner
    unless @post.user == current_user
      redirect_to posts_path, alert: 'You can only manage your own posts.'
    end
  end

  def post_params
    params.require(:post).permit(:title, :body, :status)
  end

end
