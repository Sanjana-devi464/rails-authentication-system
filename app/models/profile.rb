class Profile < ApplicationRecord
  belongs_to :user
  
  # Validations
  validates :user_id, presence: true, uniqueness: true
  validates :bio, length: { maximum: 1000 }
  validates :website, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :github_username, format: { with: /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i }, allow_blank: true
  validates :linkedin_username, format: { with: /\A[a-zA-Z0-9\-]+\z/ }, allow_blank: true
  validates :twitter_username, format: { with: /\A[a-zA-Z0-9_]+\z/ }, allow_blank: true
  validates :age, numericality: { greater_than: 13, less_than: 120 }, allow_blank: true
  
  # Enums
  enum gender: { 
    prefer_not_to_say: 0, 
    male: 1, 
    female: 2, 
    non_binary: 3, 
    other: 4 
  }
  
  enum status: { 
    available: 0, 
    busy: 1, 
    away: 2, 
    do_not_disturb: 3, 
    offline: 4 
  }
  
  enum theme_preference: { 
    system: 0, 
    light: 1, 
    dark: 2 
  }
  
  enum language: { 
    english: 0, 
    spanish: 1, 
    french: 2, 
    german: 3, 
    chinese: 4, 
    japanese: 5, 
    portuguese: 6, 
    russian: 7, 
    arabic: 8, 
    hindi: 9 
  }
  
  # Scopes
  scope :public_profiles, -> { where(public: true) }
  scope :available, -> { where(status: :available) }
  scope :with_social_links, -> { where.not(github_username: nil).or(where.not(linkedin_username: nil)) }
  
  # Callbacks
  before_save :set_default_timezone
  
  # Instance methods
  def age_from_birthday
    return nil unless birthday
    
    age = Date.current.year - birthday.year
    age -= 1 if Date.current < birthday + age.years
    age
  end
  
  def social_links
    links = {}
    links[:github] = "https://github.com/#{github_username}" if github_username.present?
    links[:linkedin] = "https://linkedin.com/in/#{linkedin_username}" if linkedin_username.present?
    links[:twitter] = "https://twitter.com/#{twitter_username}" if twitter_username.present?
    links[:website] = website if website.present?
    links
  end
  
  def display_location
    if city.present? && country.present?
      "#{city}, #{country}"
    elsif location.present?
      location
    else
      "Location not specified"
    end
  end
  
  def formatted_birthday
    birthday&.strftime("%B %d, %Y")
  end
  
  def timezone_display
    return "Not set" unless timezone.present?
    
    Time.zone = timezone
    "#{timezone} (#{Time.zone.now.strftime('%Z %z')})"
  end
  
  def career_level
    return "Entry Level" if years_of_experience.nil? || years_of_experience < 2
    return "Mid Level" if years_of_experience < 5
    return "Senior Level" if years_of_experience < 10
    "Expert Level"
  end
  
  # Class methods
  def self.analytics
    {
      total_profiles: count,
      public_profiles: public_profiles.count,
      by_location: group(:country).count.first(10),
      by_occupation: group(:occupation).count.first(10)
    }
  end
  
  private
  
  def set_default_timezone
    self.timezone ||= 'UTC'
  end
end
