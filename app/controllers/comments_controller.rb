class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_post, only: [:index, :create]
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  before_action :check_comment_owner, only: [:edit, :update]
  before_action :check_comment_permissions, only: [:destroy]
  before_action :track_user_activity

  # GET /posts/:post_id/comments
  def index
    @comments = Comment.for_post_ordered(@post, params[:order] || :oldest_first)
                      .page(params[:page])
                      .per(20)
    
    @comment = @post.comments.build if user_signed_in?
    
    respond_to do |format|
      format.html { redirect_to @post } # Redirect to post show page
      format.json { render json: @comments.as_json(include: :user) }
    end
  end

  # GET /comments/:id
  def show
    respond_to do |format|
      format.html { redirect_to @comment.post, anchor: "comment-#{@comment.id}" }
      format.json { render json: @comment.as_json(include: [:user, :post]) }
    end
  end

  # POST /posts/:post_id/comments
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        # Track creation activity (handled by model callback)
        
        format.html do
          redirect_to @post, 
                     notice: 'Comment was successfully posted!',
                     anchor: "comment-#{@comment.id}"
        end
        format.json { render json: @comment.as_json(include: :user), status: :created }
      else
        format.html do
          @comments = Comment.for_post_ordered(@post, :oldest_first)
          flash.now[:alert] = 'Failed to post comment. Please check your input.'
          render template: 'posts/show', status: :unprocessable_entity
        end
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /comments/:id/edit
  def edit
    respond_to do |format|
      format.html # Render edit form
      format.json { render json: @comment }
    end
  end

  # PATCH/PUT /comments/:id
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        UserActivity.create(
          user: current_user,
          activity_type: :feature_used,
          trackable: @comment,
          description: "Updated comment on post: #{@comment.post.title}"
        )
        
        format.html do
          redirect_to @comment.post, 
                     notice: 'Comment was successfully updated!',
                     anchor: "comment-#{@comment.id}"
        end
        format.json { render json: @comment.as_json(include: :user) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/:id
  def destroy
    post = @comment.post
    comment_id = @comment.id
    
    @comment.destroy
    
    # Track deletion activity (handled by model callback)
    
    respond_to do |format|
      format.html do
        redirect_to post, notice: 'Comment was successfully deleted!'
      end
      format.json { head :no_content }
    end
  end

  # GET /comments/my_comments
  def my_comments
    @comments = Comment.user_comments(current_user)
                      .page(params[:page])
                      .per(20)
    
    @total_count = current_user.comments.count
    
    respond_to do |format|
      format.html
      format.json { render json: @comments.as_json(include: :post) }
    end
  end

  # POST /comments/:id/report
  def report
    set_comment
    
    # Create a notification for moderators
    User.with_role(:moderator).each do |moderator|
      Notification.create_notification(
        user: moderator,
        type: 'report',
        title: 'Comment Reported',
        message: "A comment has been reported for review",
        action_url: Rails.application.routes.url_helpers.comment_path(@comment),
        data: {
          comment_id: @comment.id,
          reporter_id: current_user.id,
          post_id: @comment.post.id
        }
      )
    end
    
    respond_to do |format|
      format.html do
        redirect_to @comment.post, notice: 'Comment has been reported for review.'
      end
      format.json { render json: { status: 'reported' } }
    end
  end

  private

  def set_post
    @post = Post.friendly.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: 'Post not found.'
  end

  def set_comment
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: 'Comment not found.'
  end

  def check_comment_owner
    unless @comment.user == current_user
      redirect_to @comment.post, alert: 'You can only edit your own comments.'
    end
  end

  def check_comment_permissions
    unless @comment.can_be_deleted_by?(current_user)
      redirect_to @comment.post, alert: 'You do not have permission to delete this comment.'
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

end
