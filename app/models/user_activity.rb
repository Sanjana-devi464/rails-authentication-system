class UserActivity < ApplicationRecord
  belongs_to :user
  belongs_to :trackable, polymorphic: true, optional: true
  
  # Validations
  validates :user_id, presence: true
  validates :activity_type, presence: true
  validates :description, presence: true, length: { maximum: 500 }
  
  # Enums
  enum activity_type: {
    # Authentication activities
    sign_in: 0,
    sign_out: 1,
    password_changed: 2,
    email_changed: 3,
    account_confirmed: 4,
    
    # Profile activities
    profile_updated: 10,
    avatar_uploaded: 11,
    cover_photo_uploaded: 12,
    
    # Social activities
    post_created: 20,
    post_updated: 21,
    post_deleted: 22,
    comment_created: 23,
    like_given: 24,
    follow_user: 25,
    unfollow_user: 26,
    
    # System activities
    feature_used: 30,
    preference_changed: 31,
    notification_read: 32,
    
    # Admin activities
    role_assigned: 40,
    role_removed: 41,
    user_suspended: 42,
    user_unsuspended: 43
  }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_type, ->(type) { where(activity_type: type) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }
  scope :authentication_activities, -> { where(activity_type: [0, 1, 2, 3, 4]) }
  scope :social_activities, -> { where(activity_type: [20, 21, 22, 23, 24, 25, 26]) }
  
  # Ransack configuration for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["activity_type", "description", "ip_address", "user_agent", "trackable_type", 
     "trackable_id", "created_at", "updated_at", "id", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "trackable"]
  end
  
  # Callbacks
  before_create :set_ip_address
  after_create :cleanup_old_activities
  
  # Instance methods
  def icon_class
    case activity_type.to_sym
    when :sign_in then 'fas fa-sign-in-alt text-success'
    when :sign_out then 'fas fa-sign-out-alt text-muted'
    when :password_changed then 'fas fa-key text-warning'
    when :email_changed then 'fas fa-envelope text-info'
    when :profile_updated then 'fas fa-user-edit text-primary'
    when :avatar_uploaded then 'fas fa-image text-success'
    when :post_created then 'fas fa-plus-circle text-success'
    when :post_updated then 'fas fa-edit text-info'
    when :comment_created then 'fas fa-comment text-primary'
    when :like_given then 'fas fa-heart text-danger'
    when :follow_user then 'fas fa-user-plus text-success'
    when :role_assigned then 'fas fa-crown text-warning'
    else 'fas fa-circle text-muted'
    end
  end
  
  def formatted_description
    case activity_type.to_sym
    when :sign_in
      "Signed in from #{location_info}"
    when :sign_out
      "Signed out"
    when :profile_updated
      "Updated profile information"
    when :avatar_uploaded
      "Uploaded a new profile picture"
    when :post_created
      trackable ? "Created a new post: \"#{trackable.title&.truncate(50)}\"" : "Created a new post"
    when :comment_created
      trackable ? "Commented on a post" : "Added a comment"
    when :like_given
      "Liked a post"
    when :follow_user
      trackable ? "Started following #{trackable.display_name}" : "Followed a user"
    else
      description
    end
  end
  
  def location_info
    return 'Unknown location' unless ip_address
    
    # This would integrate with a geocoding service in production
    city.presence || country.presence || 'Unknown location'
  end
  
  def time_ago
    time_diff = Time.current - created_at
    
    case time_diff
    when 0...1.minute
      'just now'
    when 1.minute...1.hour
      "#{(time_diff / 1.minute).to_i} minute#{'s' if (time_diff / 1.minute).to_i != 1} ago"
    when 1.hour...1.day
      "#{(time_diff / 1.hour).to_i} hour#{'s' if (time_diff / 1.hour).to_i != 1} ago"
    when 1.day...1.week
      "#{(time_diff / 1.day).to_i} day#{'s' if (time_diff / 1.day).to_i != 1} ago"
    else
      created_at.strftime('%B %d, %Y')
    end
  end
  
  # Class methods
  def self.track_activity(user, activity_type, description = nil, trackable = nil, metadata = {})
    return unless user && activity_type
    
    description ||= activity_type.to_s.humanize
    
    create(
      user: user,
      activity_type: activity_type,
      description: description,
      trackable: trackable,
      metadata: metadata
    )
  end
  
  def self.user_timeline(user, limit = 20)
    where(user: user)
      .includes(:trackable)
      .recent
      .limit(limit)
  end
  
  def self.activity_summary(user, period = 1.week)
    activities = where(user: user, created_at: period.ago..Time.current)
    
    {
      total_activities: activities.count,
      sign_ins: activities.sign_in.count,
      profile_updates: activities.profile_updated.count,
      social_interactions: activities.social_activities.count,
      most_active_day: activities.group_by_day(:created_at).maximum(:count)&.first&.first,
      activity_types: activities.group(:activity_type).count
    }
  end
  
  def self.analytics_data
    recent_activities = where(created_at: 1.month.ago..Time.current)
    
    {
      total_activities: count,
      this_month: recent_activities.count,
      daily_average: recent_activities.count / 30.0,
      by_type: group(:activity_type).count,
      by_day: recent_activities.group_by_day(:created_at).count,
      top_users: recent_activities.joins(:user).group('users.username').count.first(10)
    }
  end
  
  private
  
  def set_ip_address
    # In a real application, you would get this from the request
    # self.ip_address = request.remote_ip if request
  end
  
  def cleanup_old_activities
    # Keep only the last 1000 activities per user
    user.user_activities.order(created_at: :desc).offset(1000).destroy_all
  end
end
