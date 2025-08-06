class DirectUploadsController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_user!
  
  def create
    blob = ActiveStorage::Blob.create_and_upload!(
      io: params[:file],
      filename: params[:file].original_filename,
      content_type: params[:file].content_type
    )
    
    render json: {
      attachmentId: blob.signed_id,
      url: url_for(blob),
      href: url_for(blob)
    }
  rescue => e
    render json: { error: e.message }, status: 422
  end
end
