# == Schema Information
#
# Table name: posts
#
#  id         :integer          not null, primary key
#  title      :string           not null
#  body       :text             not null
#  status     :integer          default("draft"), not null
#  slug       :string           not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_posts_on_slug     (slug) UNIQUE
#  index_posts_on_user_id  (user_id)
#  index_posts_on_status   (status)
#

class Post < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :user_activities, as: :trackable, dependent: :destroy
  has_many :comments, dependent: :destroy

  # FriendlyId for slug-based URLs
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  # Enums
  enum status: {
    draft: 0,
    published: 1
  }

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :body, presence: true, length: { minimum: 10 }
  validates :slug, presence: true, uniqueness: true
  validates :status, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :drafts, -> { where(status: :draft) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :search_by_title, ->(query) { where("title ILIKE ?", "%#{query}%") }

  # Callbacks
  before_save :generate_slug_if_needed
  after_create :track_creation_activity
  after_update :track_update_activity, if: :saved_change_to_status?
  after_destroy :track_deletion_activity

  # Instance Methods
  def draft?
    status == 'draft'
  end

  def published?
    status == 'published'
  end

  def can_be_viewed_by?(viewer)
    return true if published?
    return true if viewer == user
    return false
  end

  def excerpt(limit = 150)
    plain_text = strip_html(body)
    return plain_text if plain_text.length <= limit
    plain_text.truncate(limit, separator: ' ') + '...'
  end

  def reading_time
    # Assume average reading speed of 200 words per minute
    words = word_count
    minutes = (words / 200.0).ceil
    minutes == 1 ? "1 minute read" : "#{minutes} minutes read"
  end

  def word_count
    strip_html(body).split.size
  end

  def character_count
    strip_html(body).length
  end
  
  def html_character_count
    body.length
  end
  
  # Get plain text version of the body (strips HTML tags)
  def plain_text_body
    strip_html(body)
  end

  def status_badge_class
    case status
    when 'draft'
      'badge-secondary'
    when 'published'
      'badge-success'
    else
      'badge-light'
    end
  end

  def formatted_created_at
    created_at.strftime("%B %d, %Y")
  end

  def formatted_updated_at
    updated_at.strftime("%B %d, %Y at %I:%M %p")
  end

  # Comment-related methods
  def comments_count
    comments.count
  end

  def recent_comments(limit = 5)
    comments.recent.limit(limit).includes(:user)
  end

  def has_comments?
    comments.exists?
  end

  def can_be_commented_by?(viewer)
    return false unless published?
    return false unless viewer
    true
  end

  # Class Methods
  def self.ransackable_attributes(auth_object = nil)
    ["body", "created_at", "id", "status", "title", "updated_at", "user_id"]
  end

  def self.published_posts
    published.recent
  end

  def self.user_posts(user)
    by_user(user).recent
  end

  def self.search(query)
    return all if query.blank?
    search_by_title(query)
  end

  def self.by_status(status)
    return all if status.blank?
    where(status: status)
  end

  private

  def generate_slug_if_needed
    return if slug.present? && !title_changed?
    
    base_slug = title.parameterize
    existing_slugs = Post.where("slug LIKE ?", "#{base_slug}%").pluck(:slug)
    
    if existing_slugs.include?(base_slug)
      counter = 1
      loop do
        new_slug = "#{base_slug}-#{counter}"
        unless existing_slugs.include?(new_slug)
          self.slug = new_slug
          break
        end
        counter += 1
      end
    else
      self.slug = base_slug
    end
  end

  def track_creation_activity
    UserActivity.create(
      user: user,
      activity_type: :post_created,
      trackable: self,
      description: "Created a new post: #{title}"
    )
  end

  def track_update_activity
    if saved_change_to_status? && status == 'published'
      UserActivity.create(
        user: user,
        activity_type: :post_updated,
        trackable: self,
        description: "Published post: #{title}"
      )
    elsif saved_change_to_status? && status == 'draft'
      UserActivity.create(
        user: user,
        activity_type: :post_updated,
        trackable: self,
        description: "Unpublished post: #{title}"
      )
    end
  end

  def track_deletion_activity
    UserActivity.create(
      user: user,
      activity_type: :post_deleted,
      trackable_type: 'Post',
      trackable_id: id,
      description: "Deleted post: #{title}"
    )
  end

  # Helper method to strip HTML tags from content
  def strip_html(html_content)
    return '' if html_content.blank?
    # Use Rails' built-in strip_tags helper
    ActionController::Base.helpers.strip_tags(html_content).gsub(/\s+/, ' ').strip
  end
end
