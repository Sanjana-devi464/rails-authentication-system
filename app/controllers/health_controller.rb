class HealthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:check]
  
  def check
    begin
      # Check database connection
      ActiveRecord::Base.connection.execute("SELECT 1")
      
      # Check if we can access cache
      Rails.cache.write("health_check", Time.current)
      health_time = Rails.cache.read("health_check")
      
      render json: {
        status: "ok",
        timestamp: Time.current.iso8601,
        version: Rails.version,
        environment: Rails.env,
        database: "connected",
        cache: health_time.present? ? "connected" : "error"
      }, status: :ok
      
    rescue => e
      render json: {
        status: "error",
        message: e.message,
        timestamp: Time.current.iso8601
      }, status: :service_unavailable
    end
  end
end
