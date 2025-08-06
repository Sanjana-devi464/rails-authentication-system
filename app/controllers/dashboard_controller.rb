class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dashboard_data
  
  def index
    # Track dashboard access
    UserActivity.track_activity(
      current_user, 
      :feature_used, 
      'Accessed dashboard'
    ) rescue nil
    
    respond_to do |format|
      format.html
      format.json { render json: dashboard_json_data }
    end
  end
  
  def analytics
    @analytics_data = generate_analytics_data
    @chart_data = generate_chart_data
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics_data.merge(@chart_data) }
    end
  end
  
  def quick_stats
    render json: {
      unread_notifications: unread_notifications_count,
      recent_activities: current_user.user_activities.recent.limit(5).map(&:formatted_description),
      online_status: current_user.online?,
      member_since: current_user.created_at.strftime('%B %Y')
    }
  rescue => e
    render json: { error: 'Unable to load stats' }, status: :unprocessable_entity
  end
  
  private
  
  def set_dashboard_data
    @user = current_user
    @recent_activity = "Welcome to your enhanced dashboard!"
    @recent_activities = current_user.user_activities.recent.limit(10) rescue []
    @notifications = current_user.notifications.recent.limit(5) rescue []
    @quick_stats = calculate_quick_stats
    @suggested_actions = generate_suggested_actions
  end
  
  def calculate_quick_stats
    {
      total_activities: current_user.user_activities.count,
      this_month_activities: current_user.user_activities.where(created_at: 1.month.ago..Time.current).count,
      profile_views: current_user.profile&.profile_views || 0,
      account_age_days: (Date.current - current_user.created_at.to_date).to_i,
      last_login: current_user.last_sign_in_at&.strftime('%B %d, %Y at %I:%M %p'),
      login_count: current_user.sign_in_count || 0
    }
  rescue => e
    Rails.logger.error "Error calculating quick stats: #{e.message}"
    {}
  end
  
  def generate_suggested_actions
    suggestions = []
    
    # First post suggestion
    if current_user.posts.count == 0
      suggestions << {
        title: 'Write Your First Post',
        description: 'Share your thoughts and ideas with the community',
        action_url: new_post_path,
        priority: 'medium',
        icon: 'fas fa-pen-alt'
      }
    end
    
    # Publish drafts suggestion
    if current_user.posts.drafts.count > 0
      suggestions << {
        title: "Publish #{current_user.posts.drafts.count} Draft#{'s' if current_user.posts.drafts.count > 1}",
        description: 'You have unpublished drafts waiting to be shared',
        action_url: my_posts_posts_path,
        priority: 'medium',
        icon: 'fas fa-eye'
      }
    end
    
    # Explore community suggestion
    if current_user.user_activities.count < 10
      suggestions << {
        title: 'Explore the Community',
        description: 'Discover interesting posts and connect with other users',
        action_url: posts_path,
        priority: 'low',
        icon: 'fas fa-compass'
      }
    end
    
    suggestions.first(4) # Return top 4 suggestions
  rescue => e
    Rails.logger.error "Error generating suggestions: #{e.message}"
    []
  end
  
  def generate_analytics_data
    {
      user_stats: {
        total_users: User.count,
        active_users: User.where(last_seen_at: 1.week.ago..Time.current).count,
        new_this_month: User.where(created_at: 1.month.ago..Time.current).count
      },
      personal_stats: {
        profile_completion: @profile_completion,
        total_activities: current_user.user_activities.count,
        activities_this_month: current_user.user_activities.where(created_at: 1.month.ago..Time.current).count,
        profile_views: current_user.profile&.profile_views || 0
      }
    }
  rescue => e
    Rails.logger.error "Error generating analytics: #{e.message}"
    {}
  end
  
  def generate_chart_data
    {
      activity_chart: {
        labels: (6.days.ago.to_date..Date.current).map { |date| date.strftime('%b %d') },
        data: (6.days.ago.to_date..Date.current).map do |date|
          current_user.user_activities.where(created_at: date.beginning_of_day..date.end_of_day).count
        end
      },
      activity_types: current_user.user_activities.group(:activity_type).count.transform_keys(&:humanize)
    }
  rescue => e
    Rails.logger.error "Error generating chart data: #{e.message}"
    { activity_chart: { labels: [], data: [] }, activity_types: {} }
  end
  
  def dashboard_json_data
    {
      user: {
        id: current_user.id,
        username: current_user.username,
        display_name: current_user.display_name,
        online: current_user.online?
      },
      profile_completion: @profile_completion,
      quick_stats: @quick_stats,
      recent_activities: @recent_activities.map do |activity|
        {
          id: activity.id,
          type: activity.activity_type,
          description: activity.formatted_description,
          time_ago: activity.time_ago,
          icon: activity.icon_class
        }
      end,
      suggested_actions: @suggested_actions
    }
  rescue => e
    Rails.logger.error "Error generating dashboard JSON: #{e.message}"
    { error: 'Unable to load dashboard data' }
  end
end
