class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :notifiable, polymorphic: true, optional: true
  
  # Validations
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 1000 }
  validates :notification_type, presence: true
  
  # Enums
  enum notification_type: {
    # System notifications
    welcome: 0,
    account_verified: 1,
    password_changed: 2,
    security_alert: 3,
    
    # Social notifications
    new_follower: 10,
    post_liked: 11,
    post_commented: 12,
    mentioned: 13,
    friend_request: 14,
    
    # Content notifications
    new_post_from_followed: 20,
    post_updated: 21,
    content_featured: 22,
    
    # Admin notifications
    role_changed: 30,
    account_warning: 31,
    feature_announcement: 32,
    maintenance: 33
  }
  
  enum priority: {
    low: 0,
    normal: 1,
    high: 2,
    urgent: 3
  }
  
  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :high_priority, -> { where(priority: [:high, :urgent]) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  
  # Ransack configuration for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["title", "message", "notification_type", "priority", "read_at", 
     "created_at", "updated_at", "id", "user_id", "actor_id", "notifiable_type", "notifiable_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "actor", "notifiable"]
  end
  
  # Callbacks
  after_create :send_real_time_notification
  after_create :send_push_notification, if: :should_send_push?
  
  # Instance methods
  def read?
    read_at.present?
  end
  
  def unread?
    !read?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def mark_as_unread!
    update!(read_at: nil) if read?
  end
  
  def icon_class
    case notification_type.to_sym
    when :welcome then 'fas fa-hand-wave text-primary'
    when :account_verified then 'fas fa-check-circle text-success'
    when :password_changed then 'fas fa-key text-warning'
    when :security_alert then 'fas fa-shield-alt text-danger'
    when :new_follower then 'fas fa-user-plus text-success'
    when :post_liked then 'fas fa-heart text-danger'
    when :post_commented then 'fas fa-comment text-primary'
    when :mentioned then 'fas fa-at text-info'
    when :friend_request then 'fas fa-user-friends text-success'
    when :new_post_from_followed then 'fas fa-plus-circle text-info'
    when :role_changed then 'fas fa-crown text-warning'
    when :feature_announcement then 'fas fa-bullhorn text-primary'
    when :maintenance then 'fas fa-tools text-warning'
    else 'fas fa-bell text-muted'
    end
  end
  
  def background_color_class
    return 'bg-light' if read?
    
    case priority.to_sym
    when :urgent then 'bg-danger-subtle'
    when :high then 'bg-warning-subtle'
    when :normal then 'bg-info-subtle'
    when :low then 'bg-light'
    else 'bg-light'
    end
  end
  
  def action_url
    case notification_type.to_sym
    when :new_follower, :friend_request
      actor ? "/users/#{actor.username}" : nil
    when :post_liked, :post_commented, :new_post_from_followed
      notifiable ? "/posts/#{notifiable.id}" : nil
    when :mentioned
      url.presence
    when :role_changed
      '/profile'
    when :feature_announcement
      '/announcements'
    else
      url.presence
    end
  end
  
  def time_ago
    time_diff = Time.current - created_at
    
    case time_diff
    when 0...1.minute
      'just now'
    when 1.minute...1.hour
      "#{(time_diff / 1.minute).to_i}m ago"
    when 1.hour...1.day
      "#{(time_diff / 1.hour).to_i}h ago"
    when 1.day...1.week
      "#{(time_diff / 1.day).to_i}d ago"
    else
      created_at.strftime('%b %d')
    end
  end
  
  def summary_text
    case notification_type.to_sym
    when :new_follower
      "#{actor&.display_name || 'Someone'} started following you"
    when :post_liked
      "#{actor&.display_name || 'Someone'} liked your post"
    when :post_commented
      "#{actor&.display_name || 'Someone'} commented on your post"
    when :mentioned
      "#{actor&.display_name || 'Someone'} mentioned you"
    when :friend_request
      "#{actor&.display_name || 'Someone'} sent you a friend request"
    when :role_changed
      "Your role has been updated"
    else
      message.truncate(100)
    end
  end
  
  # Class methods
  def self.create_notification(user, type, title, message, options = {})
    return unless user && type && title && message
    
    create(
      user: user,
      notification_type: type,
      title: title,
      message: message,
      actor: options[:actor],
      notifiable: options[:notifiable],
      priority: options[:priority] || :normal,
      url: options[:url],
      metadata: options[:metadata] || {}
    )
  end
  
  def self.notify_user(user, type, options = {})
    title, message = generate_content(type, options)
    create_notification(user, type, title, message, options)
  end
  
  def self.mark_all_as_read(user)
    unread.for_user(user).update_all(read_at: Time.current)
  end
  
  def self.unread_count(user)
    unread.for_user(user).count
  end
  
  def self.recent_for_user(user, limit = 20)
    for_user(user).recent.includes(:actor, :notifiable).limit(limit)
  end
  
  def self.analytics_data
    {
      total_notifications: count,
      unread_notifications: unread.count,
      by_type: group(:notification_type).count,
      by_priority: group(:priority).count,
      this_week: this_week.count,
      most_active_users: joins(:user).group('users.username').count.first(10)
    }
  end
  
  private
  
  def send_real_time_notification
    # Broadcast to user's notification channel using Action Cable
    ActionCable.server.broadcast(
      "notifications_#{user.id}",
      {
        id: id,
        title: title,
        message: summary_text,
        icon: icon_class,
        priority: priority,
        url: action_url,
        time: time_ago
      }
    )
  rescue => e
    Rails.logger.error "Failed to send real-time notification: #{e.message}"
  end
  
  def send_push_notification
    # Integration with push notification service (e.g., Firebase, OneSignal)
    # This would be implemented based on your chosen push notification provider
    Rails.logger.info "Push notification would be sent to user #{user.id}: #{title}"
  end
  
  def should_send_push?
    user.notification_preferences&.dig('push_notifications') != false &&
    priority.in?(['high', 'urgent'])
  end
  
  def self.generate_content(type, options)
    actor_name = options[:actor]&.display_name || 'Someone'
    
    case type.to_sym
    when :welcome
      ['Welcome to our platform!', 'Thank you for joining us. Complete your profile to get started.']
    when :new_follower
      ['New Follower', "#{actor_name} started following you."]
    when :post_liked
      ['Post Liked', "#{actor_name} liked your post."]
    when :post_commented
      ['New Comment', "#{actor_name} commented on your post."]
    when :mentioned
      ['You were mentioned', "#{actor_name} mentioned you in a post."]
    when :role_changed
      ['Role Updated', 'Your account role has been updated.']
    else
      [type.to_s.humanize, options[:message] || 'You have a new notification.']
    end
  end
end
