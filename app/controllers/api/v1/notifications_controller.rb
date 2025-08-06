class Api::V1::NotificationsController < Api::V1::BaseController
  before_action :set_notification, only: [:show, :update, :destroy]

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
    @notifications = @notifications.page(params[:page]).per(params[:per_page] || 20)
    
    render json: @notifications
  end

  def show
    render json: @notification
  end

  def update
    if @notification.update(notification_params)
      render_success(@notification, "Notification updated successfully")
    else
      render_error(@notification.errors.full_messages.join(", "))
    end
  end

  def destroy
    @notification.destroy
    render_success({}, "Notification deleted successfully")
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_params
    params.require(:notification).permit(:read_at)
  end
end
