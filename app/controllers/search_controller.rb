class SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:q]
    
    if @query.present?
      @users = User.active
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR username ILIKE ? OR email ILIKE ?", 
                         "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%")
                   .limit(20)
      
      @posts = Post.published
                   .where("title ILIKE ? OR body ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .includes(:user)
                   .limit(20)
    else
      @users = []
      @posts = []
    end
  end

  def users
    @query = params[:q]
    
    if @query.present?
      @users = User.active
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR username ILIKE ? OR email ILIKE ?", 
                         "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%")
                   .page(params[:page])
                   .per(20)
    else
      @users = User.active.page(params[:page]).per(20)
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end
end
