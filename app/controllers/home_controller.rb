class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :about]

  def index
    # Allow both authenticated and non-authenticated users to see the home page
    # Authenticated users will see different content based on their status
    
    # Featured posts (most commented or recent popular posts)
    @featured_posts = Post.published
                         .includes(:user, :comments)
                         .left_joins(:comments)
                         .group('posts.id')
                         .order('COUNT(comments.id) DESC, posts.created_at DESC')
                         .limit(3)
    
    # Recent posts for the latest section
    @recent_posts = Post.published
                       .includes(:user, :comments)
                       .order(created_at: :desc)
                       .limit(8)
    
    # Community highlights
    @top_writer = User.joins(:posts)
                     .where(posts: { created_at: 1.month.ago..Time.current })
                     .group('users.id')
                     .order('COUNT(posts.id) DESC')
                     .first
    
    @most_active_commenter = User.joins(:comments)
                                .where(comments: { created_at: 1.month.ago..Time.current })
                                .group('users.id')
                                .order('COUNT(comments.id) DESC')
                                .first
  end

  def about
    # About us page - available to all users
  end
end
