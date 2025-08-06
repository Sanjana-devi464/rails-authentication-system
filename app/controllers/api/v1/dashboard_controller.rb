class Api::V1::DashboardController < Api::V1::BaseController
  def stats
    @stats = {
      users_count: User.active.count,
      posts_count: Post.published.count,
      comments_count: Comment.count,
      notifications_count: current_user.notifications.unread.count,
      recent_posts: Post.published.includes(:user).limit(5).as_json(
        only: [:id, :title, :created_at],
        include: { user: { only: [:username, :first_name, :last_name] } }
      )
    }
    
    render json: @stats
  end

  def analytics
    @analytics = {
      user_growth: user_growth_data,
      post_activity: post_activity_data,
      engagement_metrics: engagement_metrics
    }
    
    render json: @analytics
  end

  private

  def user_growth_data
    # Get user registrations for the last 30 days
    30.days.ago.to_date.upto(Date.current).map do |date|
      {
        date: date,
        count: User.where(created_at: date.beginning_of_day..date.end_of_day).count
      }
    end
  end

  def post_activity_data
    # Get post creation activity for the last 30 days
    30.days.ago.to_date.upto(Date.current).map do |date|
      {
        date: date,
        count: Post.where(created_at: date.beginning_of_day..date.end_of_day).count
      }
    end
  end

  def engagement_metrics
    {
      total_comments: Comment.count,
      average_posts_per_user: Post.count.to_f / User.count,
      active_users_today: User.where('last_seen_at > ?', 1.day.ago).count
    }
  end
end
