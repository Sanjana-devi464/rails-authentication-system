class ApplicationController < ActionController::Base
  # CSRF protection
  protect_from_forgery with: :exception
  
  # Authentication
  before_action :authenticate_user!, except: [:index]
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # User tracking and activity
  before_action :track_user_activity
  before_action :update_last_seen
  before_action :set_current_user
  
  # Internationalization
  before_action :set_locale
  
  # Performance and security
  before_action :set_cache_headers
  before_action :check_user_status
  
  # Exception handling
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameters
  rescue_from CanCan::AccessDenied, with: :access_denied
  
  # Helper methods available in views
  helper_method :current_profile, :unread_notifications_count, :user_online?, :admin_user?
  
  # Redirect to dashboard after sign in
  def after_sign_in_path_for(resource)
    if resource.sign_in_count == 1
      # First time login - go to profile setup
      edit_user_registration_path(welcome: true)
    elsif session[:return_to].present?
      session.delete(:return_to)
    elsif resource.admin?
      admin_dashboard_path rescue dashboard_path
    else
      dashboard_path
    end
  end

  # Redirect to home page after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :username, :phone])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name, :last_name, :username, :phone, :bio, :location,
      notification_preferences: {},
      profile_attributes: [
        :bio, :website, :occupation, :company, :education, :birthday,
        :github_username, :linkedin_username, :twitter_username,
        :public, :show_email, :show_phone, :theme_preference, :language,
        skills: [], interests: []
      ]
    ])
  end
  
  # User activity tracking
  def track_user_activity
    return unless user_signed_in? && !devise_controller?
    
    activity_type = determine_activity_type
    return unless activity_type
    
    UserActivity.track_activity(
      current_user,
      activity_type,
      "#{activity_type.humanize} - #{controller_name}##{action_name}",
      nil,
      {
        controller: controller_name,
        action: action_name,
        url: request.url,
        method: request.method,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    ) rescue nil # Fail silently if models aren't ready yet
  end
  
  # Update user's last seen timestamp
  def update_last_seen
    return unless user_signed_in?
    
    # Only update every 5 minutes to reduce database load
    if current_user.last_seen_at.nil? || current_user.last_seen_at < 5.minutes.ago
      current_user.update_column(:last_seen_at, Time.current) rescue nil
    end
  end
  
  # Set current user for global access
  def set_current_user
    Current.user = current_user if user_signed_in?
  rescue
    # Fail silently if Current isn't available
  end
  
  # Internationalization
  def set_locale
    if user_signed_in? && current_user.profile&.language
      I18n.locale = current_user.profile.language
    else
      I18n.locale = extract_locale_from_header || I18n.default_locale
    end
  rescue
    I18n.locale = I18n.default_locale
  end
  
  # Performance optimization
  def set_cache_headers
    if user_signed_in?
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
    end
  end
  
  # Security check
  def check_user_status
    return unless user_signed_in?
    
    if current_user.respond_to?(:suspended?) && current_user.suspended?
      sign_out current_user
      redirect_to root_path, alert: 'Your account has been suspended. Please contact support.'
    elsif current_user.respond_to?(:active) && !current_user.active?
      redirect_to root_path, notice: 'Please reactivate your account to continue.'
    end
  rescue
    # Fail silently if methods don't exist yet
  end
  
  # Helper methods
  def current_profile
    @current_profile ||= current_user&.profile
  end
  
  def unread_notifications_count
    @unread_notifications_count ||= current_user&.notifications&.unread&.count || 0
  rescue
    0
  end
  
  def user_online?(user)
    user.last_seen_at.present? && user.last_seen_at > 15.minutes.ago
  rescue
    false
  end
  
  def admin_user?
    user_signed_in? && current_user.respond_to?(:admin?) && current_user.admin?
  rescue
    false
  end
  
  # Error handling
  def record_not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
  
  def unpermitted_parameters
    redirect_back(fallback_location: root_path, alert: 'Invalid parameters submitted.')
  end
  
  def access_denied
    if user_signed_in?
      redirect_to dashboard_path, alert: 'You are not authorized to access this page.'
    else
      redirect_to new_user_session_path, alert: 'Please sign in to access this page.'
    end
  end
  
  def determine_activity_type
    case [controller_name, action_name]
    when ['dashboard', 'index'] then :feature_used
    when ['profiles', 'show'], ['profiles', 'edit'] then :feature_used
    when ['users', 'show'] then :feature_used
    when ['posts', 'index'], ['posts', 'my_posts'], ['posts', 'new'], ['posts', 'edit'], ['posts', 'search'] then :feature_used
    when ['comments', 'index'], ['comments', 'my_comments'], ['comments', 'edit'], ['comments', 'report'] then :feature_used
    else nil
    end
  end
  
  def extract_locale_from_header
    request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first&.to_sym
  end
end
