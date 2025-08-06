class UserActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_activity, only: [:show]

  def index
    @user_activities = current_user.user_activities.order(created_at: :desc)
    @user_activities = @user_activities.page(params[:page]).per(25)
  end

  def show
    # Show specific activity details
  end

  def analytics
    @total_activities = current_user.user_activities.count
    @recent_activities = current_user.user_activities.order(created_at: :desc).limit(10)
    
    # Activity breakdown by type
    @activity_breakdown = current_user.user_activities
                                      .group(:activity_type)
                                      .count
    
    # Activities by date (last 30 days)
    @activities_by_date = current_user.user_activities
                                      .where(created_at: 30.days.ago..Time.current)
                                      .group_by_day(:created_at)
                                      .count
  end

  private

  def set_user_activity
    @user_activity = current_user.user_activities.find(params[:id])
  end
end
