class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]
  before_action :ensure_own_profile, only: [:edit, :update]
  
  def index
    @q = User.ransack(params[:q])
    
    # First, ensure all users have profiles (without pagination)
    users_without_profiles = User.left_joins(:profile).where(profiles: { id: nil })
    users_without_profiles.find_each do |user|
      user.create_profile
    end
    
    # Now get paginated results with only public profiles
    @users = @q.result
               .includes(:profile)
               .joins(:profile)
               .where(profiles: { public: true })
               .page(params[:page])
               .per(20)
    
    @featured_users = User.joins(:profile)
                         .where(profiles: { public: true })
                         .where.not(id: current_user.id)
                         .order('profiles.profile_views DESC')
                         .limit(6)
    
    respond_to do |format|
      format.html
      format.json { render json: users_json_data }
    end
  end
  
  def show
    @profile = @user.profile
    
    # If profile doesn't exist, create it
    unless @profile
      @profile = @user.create_profile
    end
    
    @recent_activities = @user.user_activities.recent.limit(10)
    @social_links = @profile&.social_links || {}
    
    # Enhanced profile statistics
    @user_stats = calculate_user_stats(@user)
    @recent_posts = @user.posts.published.recent.limit(6)
    @recent_comments = @user.comments.recent.includes(:post).limit(6)
    
    # Track profile view
    if @user != current_user && @profile&.public?
      @profile.increment!(:profile_views)
      UserActivity.track_activity(
        current_user,
        :feature_used,
        "Viewed #{@user.display_name}'s profile",
        @user
      )
    end
    
    respond_to do |format|
      format.html
      format.json { render json: enhanced_profile_json_data }
    end
  end
  
  def edit
    @profile = current_user.profile || current_user.build_profile
    @skills_suggestions = get_skills_suggestions
    @interests_suggestions = get_interests_suggestions
  end
  
  def update
    @profile = current_user.profile || current_user.build_profile
    
    if @profile.update(profile_params)
      UserActivity.track_activity(
        current_user,
        :profile_updated,
        'Updated profile information'
      )
      
      redirect_to profile_path(current_user), notice: 'Profile updated successfully!'
    else
      @skills_suggestions = get_skills_suggestions
      @interests_suggestions = get_interests_suggestions
      render :edit, status: :unprocessable_entity
    end
  end
  
  def analytics
    authorize_admin!
    
    @analytics = {
      total_profiles: Profile.count,
      public_profiles: Profile.where(public: true).count,
      top_skills: Profile.where.not(skills: []).group(:skills).count.first(10),
      top_locations: Profile.group(:country).count.first(10)
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics }
    end
  end
  
  def search
    query = params[:q]&.strip
    @q = User.ransack(params[:q]) # For consistency with index action
    
    if query.present?
      @users = User.joins(:profile)
                  .where(profiles: { public: true, searchable: true })
                  .where(
                    "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.username ILIKE ? OR profiles.bio ILIKE ? OR profiles.occupation ILIKE ?",
                    "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
                  )
                  .includes(:profile)
                  .page(params[:page])
                  .per(20)
    else
      @users = User.none.page(params[:page]).per(20)
    end
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: search_json_data }
    end
  end
  
  def similar
    @user = User.find(params[:id])
    @similar_users = find_similar_users(@user).limit(10)
    
    render json: {
      user: user_summary(@user),
      similar_users: @similar_users.map { |u| user_summary(u) }
    }
  end
  
  private
  
  def set_user
    # Debug: log the parameter being used
    Rails.logger.debug "Looking for user with param: #{params[:id]}"
    
    # Try to find by username first (since routes use :username param), then fallback to ID
    @user = User.find_by(username: params[:id])
    
    # If not found by username, try by ID (for backward compatibility)
    if @user.nil?
      @user = User.find_by(id: params[:id])
      Rails.logger.debug "User found by ID: #{@user&.id}" if @user
    else
      Rails.logger.debug "User found by username: #{@user.username}"
    end
    
    # If still not found, check if the user exists but doesn't have a profile
    if @user.nil?
      Rails.logger.error "User not found with param: #{params[:id]}"
      redirect_to profiles_path, alert: 'User not found.'
      return
    end
    
    # Ensure user has a profile
    unless @user.profile
      Rails.logger.warn "User #{@user.id} (#{@user.username}) doesn't have a profile. Creating one."
      @user.create_profile
    end
  end
  
  def ensure_own_profile
    unless @user == current_user || current_user.admin?
      redirect_to profile_path(@user), alert: 'You can only edit your own profile.'
    end
  end
  
  def authorize_admin!
    unless current_user.admin?
      redirect_to dashboard_path, alert: 'Access denied.'
    end
  end
  
  def profile_params
    params.require(:profile).permit(
      :bio, :website, :occupation, :company, :education, :birthday,
      :location, :city, :country, :timezone, :gender, :age,
      :github_username, :linkedin_username, :twitter_username,
      :instagram_username, :facebook_username,
      :public, :show_email, :show_phone, :searchable,
      :theme_preference, :language, :status,
      :years_of_experience, :salary_range_min, :salary_range_max,
      skills: [], interests: []
    )
  end
  
  def get_skills_suggestions
    [
      'Ruby', 'Rails', 'JavaScript', 'Python', 'React', 'Vue.js', 'Node.js',
      'PostgreSQL', 'MySQL', 'Redis', 'Docker', 'Kubernetes', 'AWS', 'Azure',
      'Git', 'HTML', 'CSS', 'TypeScript', 'GraphQL', 'REST APIs',
      'Machine Learning', 'Data Science', 'DevOps', 'Agile', 'Scrum'
    ]
  end
  
  def get_interests_suggestions
    [
      'Web Development', 'Mobile Development', 'Data Science', 'Machine Learning',
      'Artificial Intelligence', 'Blockchain', 'Cybersecurity', 'Cloud Computing',
      'DevOps', 'UI/UX Design', 'Product Management', 'Entrepreneurship',
      'Open Source', 'Tech Blogging', 'Mentoring', 'Speaking', 'Teaching'
    ]
  end
  
  def users_json_data
    {
      users: @users.map { |user| user_summary(user) },
      featured_users: @featured_users.map { |user| user_summary(user) },
      total_count: @q.result.count,
      current_page: params[:page]&.to_i || 1
    }
  end
  
  def profile_json_data
    {
      user: user_detail(@user),
      profile: @profile&.as_json(except: [:created_at, :updated_at]),
      recent_activities: @recent_activities.map do |activity|
        {
          type: activity.activity_type,
          description: activity.formatted_description,
          time_ago: activity.time_ago
        }
      end,
      social_links: @social_links,
      is_own_profile: @user == current_user
    }
  end
  
  def search_json_data
    {
      query: params[:q],
      results: @users.map { |user| user_summary(user) },
      count: @users.respond_to?(:total_count) ? @users.total_count : @users.count,
      current_page: params[:page]&.to_i || 1
    }
  end
  
  def user_summary(user)
    {
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      bio: user.profile&.bio&.truncate(100),
      location: user.profile&.display_location,
      occupation: user.profile&.occupation,
      avatar_url: user.avatar_url,
      online: user.online?,
      member_since: user.created_at.strftime('%B %Y')
    }
  end
  
  def user_detail(user)
    user_summary(user).merge(
      email: user.show_email? ? user.email : nil,
      phone: user.show_phone? ? user.phone : nil,
      full_name: user.full_name,
      skills: user.profile&.skills || [],
      interests: user.profile&.interests || [],
      social_links: user.profile&.social_links || {},
      last_seen: user.last_seen_at&.strftime('%B %d, %Y at %I:%M %p'),
      sign_in_count: user.sign_in_count
    )
  end
  
  def find_similar_users(user)
    return User.none unless user.profile
    
    # Find users with similar skills or interests
    User.joins(:profile)
        .where.not(id: user.id)
        .where(profiles: { public: true })
        .where(
          "profiles.skills && ARRAY[?] OR profiles.interests && ARRAY[?] OR profiles.occupation = ?",
          user.profile.skills,
          user.profile.interests,
          user.profile.occupation
        )
        .order(:created_at)
  end

  def calculate_user_stats(user)
    {
      total_posts: user.posts.count,
      published_posts: user.posts.published.count,
      draft_posts: user.posts.drafts.count,
      total_comments: user.comments.count,
      total_activities: user.user_activities.count,
      profile_views: user.profile&.profile_views || 0,
      member_since: user.created_at,
      last_activity: user.user_activities.maximum(:created_at),
      comments_this_month: user.comments.where(created_at: 1.month.ago..Time.current).count,
      posts_this_month: user.posts.where(created_at: 1.month.ago..Time.current).count,
      avg_comments_per_post: user.posts.published.count > 0 ? 
        (user.posts.published.joins(:comments).count.to_f / user.posts.published.count).round(1) : 0,
      most_active_day: calculate_most_active_day(user),
      activity_score: calculate_activity_score(user)
    }
  end

  def calculate_most_active_day(user)
    activities_by_day = user.user_activities.group_by { |a| a.created_at.wday }
    return 'No activity yet' if activities_by_day.empty?
    
    most_active_day_number = activities_by_day.max_by { |_, activities| activities.count }.first
    Date::DAYNAMES[most_active_day_number]
  end

  def calculate_activity_score(user)
    # Simple activity score based on posts, comments, and activities
    score = 0
    score += user.posts.published.count * 10  # 10 points per published post
    score += user.comments.count * 5          # 5 points per comment
    score += user.user_activities.count * 1   # 1 point per activity
    score += (user.profile&.profile_views || 0) * 0.1  # 0.1 points per profile view
    score.round
  end

  def enhanced_profile_json_data
    {
      user: user_detail(@user),
      profile: @profile&.as_json(except: [:created_at, :updated_at]),
      stats: @user_stats,
      recent_posts: @recent_posts.as_json(only: [:id, :title, :slug, :created_at], methods: [:comments_count]),
      recent_comments: @recent_comments.as_json(only: [:id, :content, :created_at], include: { post: { only: [:id, :title, :slug] } }),
      recent_activities: @recent_activities.map do |activity|
        {
          type: activity.activity_type,
          description: activity.formatted_description,
          time_ago: activity.time_ago
        }
      end,
      social_links: @social_links,
      is_own_profile: @user == current_user
    }
  end
end
