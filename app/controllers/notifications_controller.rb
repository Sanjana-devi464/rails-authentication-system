class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_as_read, :mark_as_unread, :destroy]
  
  def index
    @notifications = current_user.notifications
                                .includes(:actor, :notifiable)
                                .recent
                                .page(params[:page])
                                .per(20)
    
    @unread_count = current_user.notifications.unread.count
    @filter = params[:filter] || 'all'
    
    case @filter
    when 'unread'
      @notifications = @notifications.unread
    when 'system'
      @notifications = @notifications.where(notification_type: [0, 1, 2, 3, 32, 33])
    when 'social'
      @notifications = @notifications.where(notification_type: [10, 11, 12, 13, 14])
    end
    
    respond_to do |format|
      format.html
      format.json { render json: notifications_json_data }
    end
  end
  
  def show
    @notification.mark_as_read! if @notification.unread?
    
    respond_to do |format|
      format.html { redirect_to @notification.action_url || notifications_path }
      format.json { render json: notification_json_data }
    end
  end
  
  def mark_as_read
    @notification.mark_as_read!
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { status: 'read' } }
    end
  end
  
  def mark_as_unread
    @notification.mark_as_unread!
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { status: 'unread' } }
    end
  end
  
  def mark_all_as_read
    Notification.mark_all_as_read(current_user)
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'All notifications marked as read.' }
      format.json { render json: { message: 'All notifications marked as read' } }
    end
  end
  
  def destroy
    @notification.destroy
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'Notification deleted.' }
      format.json { render json: { message: 'Notification deleted' } }
    end
  end
  
  def clear_all
    current_user.notifications.destroy_all
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'All notifications cleared.' }
      format.json { render json: { message: 'All notifications cleared' } }
    end
  end
  
  def preferences
    @preferences = current_user.notification_preferences || {}
    
    if request.post?
      current_user.update!(notification_preferences: notification_preferences_params)
      redirect_to notification_preferences_path, notice: 'Preferences updated successfully.'
    end
  end
  
  def recent
    @recent_notifications = current_user.notifications
                                       .recent
                                       .limit(10)
                                       .includes(:actor)
    
    render json: {
      notifications: @recent_notifications.map do |notification|
        {
          id: notification.id,
          title: notification.title,
          message: notification.summary_text,
          time_ago: notification.time_ago,
          read: notification.read?,
          icon: notification.icon_class,
          url: notification.action_url,
          priority: notification.priority
        }
      end,
      unread_count: current_user.notifications.unread.count
    }
  end
  
  def test_notification
    return unless Rails.env.development?
    
    Notification.create_notification(
      current_user,
      :feature_announcement,
      'Test Notification',
      'This is a test notification to check the system.',
      { priority: :normal }
    )
    
    redirect_to notifications_path, notice: 'Test notification created.'
  end
  
  private
  
  def set_notification
    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to notifications_path, alert: 'Notification not found.'
  end
  
  def notification_preferences_params
    params.require(:notification_preferences).permit(
      :email_notifications,
      :push_notifications,
      :sms_notifications,
      :new_follower,
      :post_liked,
      :post_commented,
      :mentioned,
      :friend_request,
      :system_updates,
      :marketing_emails,
      :weekly_digest,
      :security_alerts
    )
  end
  
  def notifications_json_data
    {
      notifications: @notifications.map do |notification|
        {
          id: notification.id,
          type: notification.notification_type,
          title: notification.title,
          message: notification.summary_text,
          time_ago: notification.time_ago,
          read: notification.read?,
          icon: notification.icon_class,
          priority: notification.priority,
          url: notification.action_url,
          actor: notification.actor ? {
            id: notification.actor.id,
            username: notification.actor.username,
            display_name: notification.actor.display_name,
            avatar_url: notification.actor.avatar_url
          } : nil
        }
      end,
      unread_count: @unread_count,
      current_page: params[:page]&.to_i || 1,
      total_pages: @notifications.respond_to?(:total_pages) ? @notifications.total_pages : 1
    }
  end
  
  def notification_json_data
    {
      id: @notification.id,
      type: @notification.notification_type,
      title: @notification.title,
      message: @notification.message,
      read: @notification.read?,
      created_at: @notification.created_at.iso8601,
      url: @notification.action_url,
      actor: @notification.actor ? {
        id: @notification.actor.id,
        username: @notification.actor.username,
        display_name: @notification.actor.display_name,
        avatar_url: @notification.actor.avatar_url
      } : nil,
      notifiable: @notification.notifiable ? {
        type: @notification.notifiable_type,
        id: @notification.notifiable_id
      } : nil
    }
  end
end
