class User < ApplicationRecord
  # Devise modules for authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable

  # Role management
  rolify
  
  # Tagging system
  acts_as_taggable_on :skills, :interests
  
  # SEO-friendly URLs
  extend FriendlyId
  friendly_id :username, use: :slugged
  
  # File attachments
  has_many_attached :documents
  
  # Associations
  has_one :profile, dependent: :destroy
  has_many :user_activities, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :username, presence: true, uniqueness: true, 
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" },
            length: { minimum: 3, maximum: 30 }
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A[\+]?[1-9][\d\s\-\(\)]{7,15}\z/, message: "invalid format" }, allow_blank: true
  
  # Geocoding for location features
  geocoded_by :location
  after_validation :geocode, if: ->(obj){ obj.location.present? and obj.location_changed? }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_role, ->(role) { with_role(role) }
  scope :online, -> { where('last_seen_at > ?', 15.minutes.ago) }
  
  # Callbacks
  after_create :create_default_profile
  after_create :assign_default_role
  after_update :track_profile_updates
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def display_name
    username.presence || full_name
  end
  
  def avatar_url(size = :medium)
    gravatar_url(size)
  end
  
  def online?
    last_seen_at.present? && last_seen_at > 15.minutes.ago
  end
  
  def admin?
    has_role?(:admin)
  end
  
  def moderator?
    has_role?(:moderator)
  end
  
  def premium?
    has_role?(:premium)
  end
  
  def profile_complete?
    bio.present? && location.present?
  end
  
  def activity_score
    user_activities.where(created_at: 1.month.ago..Time.current).count
  end
  
  def similar_users
    User.joins(:profile)
        .where.not(id: id)
        .where(profiles: { interests: profile&.interests })
        .limit(10)
  end
  
  def update_last_seen!
    update_column(:last_seen_at, Time.current)
  end
  
  # Class methods
  def self.search(query)
    if query.present?
      where("first_name ILIKE ? OR last_name ILIKE ? OR username ILIKE ? OR email ILIKE ?", 
            "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
    else
      all
    end
  end
  
  def self.analytics_data
    {
      total_users: count,
      active_users: active.count,
      new_this_month: where(created_at: 1.month.ago..Time.current).count,
      online_now: online.count,
      by_role: group_by_role_counts
    }
  end
  
  private
  
  def create_default_profile
    create_profile unless profile
  end
  
  def assign_default_role
    add_role(:user) if roles.blank?
  end
  
  def track_profile_updates
    if saved_changes.keys.intersect?(['first_name', 'last_name', 'bio', 'location'])
      UserActivity.create(
        user: self,
        activity_type: 'profile_updated',
        description: 'Profile information updated'
      )
    end
  end
  
  def size_dimensions(size)
    case size
    when :small then 50
    when :medium then 100
    when :large then 200
    else 100
    end
  end
  
  def gravatar_url(size = :medium)
    gravatar_id = Digest::MD5::hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}?s=#{size_dimensions(size)}&d=identicon"
  end
  
  def self.group_by_role_counts
    joins(:roles).group('roles.name').count
  end
end
