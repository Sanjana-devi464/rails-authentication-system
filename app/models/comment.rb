# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  content    :text             not null
#  post_id    :integer          not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_comments_on_post_id              (post_id)
#  index_comments_on_user_id              (user_id)
#  index_comments_on_post_id_created_at   (post_id, created_at)
#

class Comment < ApplicationRecord
  # Associations
  belongs_to :post
  belongs_to :user
  has_many :user_activities, as: :trackable, dependent: :destroy

  # Validations
  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }
  validates :post_id, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :for_post, ->(post) { where(post: post) }
  scope :by_user, ->(user) { where(user: user) }

  # Ransack configuration for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["content", "created_at", "id", "post_id", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["post", "user"]
  end

  # Callbacks
  after_create :track_creation_activity
  after_create :notify_post_author
  after_destroy :track_deletion_activity

  # Instance Methods
  def can_be_edited_by?(viewer)
    return false unless viewer
    viewer == user || viewer.admin?
  end

  def can_be_deleted_by?(viewer)
    return false unless viewer
    viewer == user || viewer == post.user || viewer.admin?
  end

  def excerpt(limit = 100)
    return content if content.length <= limit
    content.truncate(limit, separator: ' ') + '...'
  end

  def formatted_created_at
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end

  def time_ago
    time_ago_in_words = distance_of_time_in_words(created_at, Time.current)
    "#{time_ago_in_words} ago"
  end

  def word_count
    content.split.size
  end

  def character_count
    content.length
  end

  # Class Methods
  def self.recent_comments(limit = 10)
    recent.limit(limit).includes(:user, :post)
  end

  def self.for_post_ordered(post, order = :oldest_first)
    case order.to_sym
    when :recent
      for_post(post).recent.includes(:user)
    else
      for_post(post).oldest_first.includes(:user)
    end
  end

  def self.user_comments(user)
    by_user(user).recent.includes(:post)
  end

  private

  def track_creation_activity
    UserActivity.create(
      user: user,
      activity_type: :comment_created,
      trackable: self,
      description: "Commented on post: #{post.title}"
    )
  end

  def track_deletion_activity
    UserActivity.create(
      user: user,
      activity_type: :feature_used,
      trackable_type: 'Comment',
      trackable_id: id,
      description: "Deleted comment on post: #{post.title}"
    )
  end

  def notify_post_author
    return if user == post.user # Don't notify if commenting on own post
    
    Notification.create_notification(
      user: post.user,
      type: 'comment',
      title: 'New Comment on Your Post',
      message: "#{user.display_name} commented on your post '#{post.title}'",
      action_url: Rails.application.routes.url_helpers.post_path(post, anchor: "comment-#{id}"),
      data: {
        post_id: post.id,
        comment_id: id,
        commenter_id: user.id
      }
    )
  end

  # Helper method for time calculations (if not available globally)
  def distance_of_time_in_words(from_time, to_time)
    distance_in_minutes = ((to_time - from_time) / 60).round
    
    case distance_in_minutes
    when 0
      'less than a minute'
    when 1
      '1 minute'
    when 2..44
      "#{distance_in_minutes} minutes"
    when 45..89
      'about 1 hour'
    when 90..1439
      "about #{(distance_in_minutes.to_f / 60.0).round} hours"
    when 1440..2519
      '1 day'
    when 2520..43199
      "#{(distance_in_minutes.to_f / 1440.0).round} days"
    when 43200..86399
      'about 1 month'
    when 86400..525599
      "#{(distance_in_minutes.to_f / 43200.0).round} months"
    else
      "#{(distance_in_minutes.to_f / 525600.0).round} years"
    end
  end
end
