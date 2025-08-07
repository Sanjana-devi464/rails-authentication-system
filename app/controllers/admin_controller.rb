class AdminController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :ensure_admin_access!
  
  def index
    @stats = {
      total_users: User.count,
      total_posts: Post.count,
      total_comments: Comment.count,
      total_activities: UserActivity.count,
      users_this_month: User.where(created_at: 1.month.ago..Time.current).count,
      posts_this_month: Post.where(created_at: 1.month.ago..Time.current).count,
      comments_this_month: Comment.where(created_at: 1.month.ago..Time.current).count,
      online_users: User.where('last_seen_at > ?', 15.minutes.ago).count
    }
    
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_posts = Post.includes(:user).order(created_at: :desc).limit(5)
    @recent_comments = Comment.includes(:user, :post).order(created_at: :desc).limit(5)
    @recent_activities = UserActivity.includes(:user).order(created_at: :desc).limit(10)
    
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end
  
  def users
    @q = User.ransack(params[:q])
    @users = @q.result
               .includes(:profile, :posts, :comments)
               .order(:created_at)
               .page(params[:page])
               .per(25)
    
    @total_users = User.count
    @admin_users = User.with_role(:admin).count
    @recent_registrations = User.where(created_at: 7.days.ago..Time.current).count
    
    respond_to do |format|
      format.html
      format.json { render json: users_json_data }
    end
  end
  
  def posts
    @q = Post.ransack(params[:q])
    @posts = @q.result
               .includes(:user, :comments)
               .order(created_at: :desc)
               .page(params[:page])
               .per(25)
    
    @total_posts = Post.count
    @published_posts = Post.published.count
    @draft_posts = Post.draft.count
    @posts_this_week = Post.where(created_at: 7.days.ago..Time.current).count
    
    respond_to do |format|
      format.html
      format.json { render json: posts_json_data }
    end
  end
  
  def comments
    @q = Comment.ransack(params[:q])
    @comments = @q.result
                  .includes(:user, :post)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(25)
    
    @total_comments = Comment.count
    @comments_this_week = Comment.where(created_at: 7.days.ago..Time.current).count
    @avg_comments_per_post = Post.published.count > 0 ? (Comment.count.to_f / Post.published.count).round(2) : 0
    
    respond_to do |format|
      format.html
      format.json { render json: comments_json_data }
    end
  end
  
  def analytics
    @user_analytics = {
      total_users: User.count,
      active_users: User.where('last_seen_at > ?', 7.days.ago).count,
      new_users_this_month: User.where(created_at: 1.month.ago..Time.current).count,
      users_by_role: Role.all.map { |role| { name: role.name, count: User.with_role(role.name).count } }
    }
    
    @content_analytics = {
      total_posts: Post.count,
      published_posts: Post.published.count,
      draft_posts: Post.draft.count,
      total_comments: Comment.count,
      avg_comments_per_post: Post.published.count > 0 ? (Comment.count.to_f / Post.published.count).round(2) : 0
    }
    
    @activity_analytics = {
      total_activities: UserActivity.count,
      activities_this_month: UserActivity.where(created_at: 1.month.ago..Time.current).count,
      most_active_users: User.joins(:user_activities)
                            .group('users.id')
                            .order('COUNT(user_activities.id) DESC')
                            .limit(10)
                            .pluck(:username, 'COUNT(user_activities.id)')
    }
    
    respond_to do |format|
      format.html
      format.json { render json: { user: @user_analytics, content: @content_analytics, activity: @activity_analytics } }
    end
  end
  
  def destroy_user
    @user = User.find(params[:id])
    
    # Prevent deletion of the admin user
    if @user.admin? && @user.email == 'sanjanade464@gmail.com'
      redirect_to admin_users_path, alert: 'Cannot delete the super admin user.'
      return
    end
    
    # Track this action
    UserActivity.track_activity(
      current_user,
      :admin_action,
      "Deleted user: #{@user.display_name} (#{@user.email})"
    )
    
    @user.destroy
    redirect_to admin_users_path, notice: "User #{@user.display_name} has been deleted successfully."
  end
  
  def destroy_post
    @post = Post.find(params[:id])
    
    UserActivity.track_activity(
      current_user,
      :admin_action,
      "Deleted post: #{@post.title} by #{@post.user.display_name}"
    )
    
    @post.destroy
    redirect_to admin_posts_path, notice: "Post '#{@post.title}' has been deleted successfully."
  end
  
  def destroy_comment
    @comment = Comment.find(params[:id])
    
    UserActivity.track_activity(
      current_user,
      :admin_action,
      "Deleted comment by #{@comment.user.display_name}"
    )
    
    @comment.destroy
    redirect_to admin_comments_path, notice: "Comment has been deleted successfully."
  end
  
  def system_info
    @system_info = {
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION,
      environment: Rails.env,
      database_adapter: ActiveRecord::Base.connection.adapter_name,
      total_database_size: calculate_database_size,
      uptime: calculate_uptime,
      memory_usage: calculate_memory_usage
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @system_info }
    end
  end
  
  private
  
  def ensure_admin_access!
    unless current_user.email == 'sanjanade464@gmail.com'
      redirect_to dashboard_path, alert: 'Access denied. You are not authorized to access the admin panel.'
    end
  end
  
  def users_json_data
    {
      users: @users.map do |user|
        {
          id: user.id,
          username: user.username,
          email: user.email,
          full_name: user.full_name,
          created_at: user.created_at.strftime('%B %d, %Y'),
          posts_count: user.posts.count,
          comments_count: user.comments.count,
          last_seen: user.last_seen_at&.strftime('%B %d, %Y at %I:%M %p'),
          online: user.online?,
          admin: user.admin?
        }
      end,
      total_count: @q.result.count,
      current_page: params[:page]&.to_i || 1
    }
  end
  
  def posts_json_data
    {
      posts: @posts.map do |post|
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          status: post.status,
          author: post.user.display_name,
          created_at: post.created_at.strftime('%B %d, %Y'),
          comments_count: post.comments.count,
          excerpt: post.body&.truncate(100)
        }
      end,
      total_count: @q.result.count,
      current_page: params[:page]&.to_i || 1
    }
  end
  
  def comments_json_data
    {
      comments: @comments.map do |comment|
        {
          id: comment.id,
          content: comment.content.truncate(100),
          author: comment.user.display_name,
          post_title: comment.post.title,
          post_slug: comment.post.slug,
          created_at: comment.created_at.strftime('%B %d, %Y at %I:%M %p')
        }
      end,
      total_count: @q.result.count,
      current_page: params[:page]&.to_i || 1
    }
  end
  
  def calculate_database_size
    case ActiveRecord::Base.connection.adapter_name.downcase
    when 'sqlite'
      File.size(Rails.root.join('db', 'development.sqlite3')) rescue 0
    when 'postgresql'
      ActiveRecord::Base.connection.execute("SELECT pg_size_pretty(pg_database_size(current_database()));").first['pg_size_pretty'] rescue 'Unknown'
    else
      'Unknown'
    end
  end
  
  def calculate_uptime
    return 'Unknown' unless defined?(Rails.application.config.started_at)
    
    start_time = Rails.application.config.started_at || Time.current
    uptime_seconds = Time.current - start_time
    
    days = (uptime_seconds / 1.day).to_i
    hours = ((uptime_seconds % 1.day) / 1.hour).to_i
    minutes = ((uptime_seconds % 1.hour) / 1.minute).to_i
    
    "#{days}d #{hours}h #{minutes}m"
  end
  
  def calculate_memory_usage
    # This is a simplified memory calculation
    begin
      memory_usage = `ps -o pid,rss,command -p #{Process.pid}`.split("\n")[1].split[1].to_i
      "#{(memory_usage / 1024.0).round(2)} MB"
    rescue
      'Unknown'
    end
  end
end
