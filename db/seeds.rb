# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Create admin user
admin_email = 'sanjanade464@gmail.com'
admin_user = User.find_or_initialize_by(email: admin_email)

if admin_user.new_record?
  admin_user.assign_attributes(
    username: 'admin',
    first_name: 'Admin',
    last_name: 'User',
    password: 'password123',
    password_confirmation: 'password123'
  )
  
  if admin_user.save
    puts "✅ Admin user created successfully with email: #{admin_email}"
  else
    puts "❌ Failed to create admin user: #{admin_user.errors.full_messages.join(', ')}"
  end
else
  puts "✅ Admin user already exists with email: #{admin_email}"
end

# Ensure admin user has admin role
admin_role = Role.find_or_create_by(name: 'admin')
unless admin_user.has_role?(:admin)
  admin_user.add_role(:admin)
  puts "✅ Admin role assigned to user: #{admin_email}"
else
  puts "✅ Admin user already has admin role"
end

# Create some sample data if needed
if Rails.env.development?
  # Create sample users
  5.times do |i|
    user = User.find_or_initialize_by(email: "user#{i+1}@example.com")
    
    if user.new_record?
      user.assign_attributes(
        username: "user#{i+1}",
        first_name: "User",
        last_name: "Number#{i+1}",
        password: "password123",
        password_confirmation: "password123"
      )
      
      if user.save
        puts "✅ Created sample user: user#{i+1}@example.com"
      else
        puts "❌ Failed to create user: #{user.errors.full_messages.join(', ')}"
      end
    end
    
    # Create profile for each user
    if user.persisted? && !user.profile
      user.create_profile(
        bio: "This is a sample bio for User #{i+1}",
        public: true,
        searchable: true
      )
    end
  end
  
  puts "✅ Sample users created for development"
  
  # Create sample posts
  User.where.not(email: admin_email).limit(3).each do |user|
    2.times do |i|
      post = user.posts.find_or_initialize_by(title: "Sample Post #{i+1} by #{user.username}")
      
      if post.new_record?
        post.assign_attributes(
          body: "This is a sample post content for testing purposes. It contains some Lorem ipsum text to make it look realistic.",
          status: ['draft', 'published'].sample
        )
        
        if post.save
          puts "✅ Created sample post: #{post.title}"
        else
          puts "❌ Failed to create post: #{post.errors.full_messages.join(', ')}"
        end
      end
    end
  end
  
  puts "✅ Sample posts created for development"
end

puts "\n🎉 Database seeding completed!"
puts "👤 Admin Access: #{admin_email}"
puts "🔐 Admin Password: password123"
puts "🌐 Admin Panel: http://localhost:3000/admin"
