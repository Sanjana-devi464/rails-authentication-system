# 🚀 Ruby on Rails Authentication System

**Created by Sanjana Devi**

A comprehensive, modern Ruby on Rails authentication system featuring user management, social blogging platform, role-based access control, rich text editing, and advanced user analytics. Built with enterprise-grade security and scalability in mind.

## 📚 Complete Documentation

For detailed documentation covering all features, implementation details, and deployment instructions, please see:

**[📖 PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)**

## ⚡ Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd ror-project

# Install dependencies
bundle install
# Note: yarn install not needed (using importmap)

# Setup database
rails db:setup
rails db:migrate
rails db:seed

# Start the server
rails server
```

Visit `http://localhost:3000` to access the application.

## ✨ Key Features

### 🔐 **Authentication & User Management**
- **Devise Integration** - Complete authentication system with registration, login, password reset
- **Role-Based Access Control** - Admin, moderator, and user roles with Rolify
- **User Profiles** - Comprehensive profiles with skills, interests, social links, and geocoding
- **Account Security** - Session management, activity tracking, and security features
- **OAuth Integration** - Google OAuth support for social login

### 📝 **Content Management System**
- **Posts System** - Create, edit, publish blog posts with SEO-friendly URLs
- **Rich Text Editor** - Trix editor integration with image upload support
- **Comment System** - Nested comments with moderation capabilities  
- **Content Status** - Draft/published workflow for posts
- **Search & Filtering** - Advanced search with Ransack integration

### 🎨 **Modern User Experience**
- **Responsive Design** - Bootstrap 5.3 with mobile-first approach
- **Interactive Dashboard** - Personalized user dashboard with analytics
- **Real-time Features** - Live notifications and activity feeds
- **Advanced UI Components** - Modern cards, modals, and form controls
- **Accessibility** - WCAG compliant design patterns

### 📊 **Analytics & Insights**
- **User Activity Tracking** - Comprehensive activity logging and analytics
- **Profile Analytics** - Profile views, activity scores, and engagement metrics
- **Content Analytics** - Post performance and reading time calculations
- **System Statistics** - Platform-wide statistics and reporting

### �️ **Security & Performance**
- **CSRF Protection** - Built-in Rails security features
- **SQL Injection Prevention** - Parameterized queries and Active Record protection
- **Geocoding** - Location-based features with privacy controls
- **File Management** - Active Storage integration for secure file uploads
- **Performance Optimization** - Database indexing and query optimization

## 🏗️ Architecture Overview

### **Core Technologies**
- **Ruby on Rails 7.1** - Modern web application framework
- **SQLite3** (Development) / **PostgreSQL** (Production)
- **Devise** - Authentication and user management
- **Stimulus** - JavaScript framework for enhanced interactivity
- **Bootstrap 5.3** - Responsive UI framework

### **Key Gems & Libraries**
```ruby
# Authentication & Authorization
gem "devise"              # Authentication solution
gem "rolify"              # Role management
gem "cancancan"           # Authorization framework

# Content & Search
gem "acts-as-taggable-on" # Tagging system
gem "friendly_id"         # SEO-friendly URLs
gem "ransack"             # Search functionality
gem "kaminari"            # Pagination

# Utility & Enhancement
gem "geocoder"            # Location services
gem "meta-tags"           # SEO optimization
gem "oauth2"              # OAuth integration
```

### **Database Schema**
- **Users** - Authentication, profile data, and preferences
- **Profiles** - Extended user information and social data
- **Posts** - Blog posts with slug-based URLs and status management
- **Comments** - User-generated content with threading support
- **Notifications** - System-wide notification management
- **User Activities** - Comprehensive activity tracking
- **Roles & Permissions** - Role-based access control system

## 🚀 Features Breakdown

### **Authentication Features**
- ✅ User registration with email validation
- ✅ Secure login/logout with "Remember Me" functionality
- ✅ Password reset via email
- ✅ Account activation and email confirmation
- ✅ Session management with timeout
- ✅ Google OAuth integration
- ✅ Multi-factor authentication ready

### **User Profile System**
- ✅ Comprehensive user profiles with bio, location, skills
- ✅ Social media integration (GitHub, LinkedIn, Twitter, etc.)
- ✅ Avatar support with Gravatar integration
- ✅ Privacy controls (public/private profiles)
- ✅ Profile analytics and view tracking
- ✅ User discovery and similarity matching

### **Content Management**
- ✅ Rich text blog posts with Trix editor
- ✅ Draft and published post states
- ✅ SEO-optimized URLs with FriendlyId
- ✅ Image uploads with Active Storage
- ✅ Comment system with user attribution
- ✅ Content moderation tools
- ✅ Reading time calculation

### **Search & Discovery**
- ✅ Advanced search across users and posts
- ✅ Filter by location, skills, interests
- ✅ Tag-based content organization
- ✅ Pagination for large datasets
- ✅ Search result optimization

### **Admin Features**
- ✅ Role-based admin access
- ✅ User management and moderation
- ✅ Content management and oversight
- ✅ System analytics and reporting
- ✅ Activity monitoring and logging

## 🛠️ Development Commands

```bash
# Database operations
rails db:create          # Create database
rails db:migrate         # Run migrations
rails db:seed            # Seed with sample data
rails db:reset           # Reset database

# Testing
rails test               # Run test suite
rails test:system        # Run system tests

# Console access
rails console            # Interactive Rails console
rails dbconsole         # Database console

# Code generation
rails generate model ModelName
rails generate controller ControllerName
rails generate migration MigrationName

# Asset management (using importmap)
./bin/importmap pin package_name
./bin/importmap unpin package_name
```

## 📁 Project Structure

```
app/
├── controllers/           # Request handling and business logic
│   ├── application_controller.rb
│   ├── dashboard_controller.rb
│   ├── home_controller.rb
│   ├── posts_controller.rb
│   ├── profiles_controller.rb
│   ├── comments_controller.rb
│   ├── notifications_controller.rb
│   ├── user_activities_controller.rb
│   ├── search_controller.rb
│   ├── api/v1/            # REST API endpoints
│   └── users/             # Devise custom controllers
├── models/                # Data models and business logic
│   ├── user.rb           # User authentication and profile
│   ├── profile.rb        # Extended user information
│   ├── post.rb           # Blog posts and content
│   ├── comment.rb        # User comments
│   ├── notification.rb   # System notifications
│   ├── user_activity.rb  # Activity tracking
│   └── role.rb           # Role management
├── views/                 # HTML templates and layouts
│   ├── layouts/          # Application layouts
│   ├── devise/           # Authentication views
│   ├── dashboard/        # User dashboard
│   ├── posts/            # Blog post views
│   ├── profiles/         # User profile views
│   └── shared/           # Reusable components
├── javascript/            # Stimulus controllers
└── assets/               # Stylesheets and images

config/
├── routes.rb             # URL routing configuration  
├── application.rb        # Application configuration
├── database.yml          # Database configuration
└── initializers/         # Framework initialization

db/
├── migrate/              # Database migrations
└── schema.rb            # Current database schema
```

## 🌐 API Endpoints

### **Authentication API**
- `POST /api/v1/auth/login` - User authentication
- `DELETE /api/v1/auth/logout` - User logout
- `GET /api/v1/auth/profile` - Current user profile

### **Posts API**
- `GET /api/v1/posts` - List posts with pagination
- `POST /api/v1/posts` - Create new post
- `GET /api/v1/posts/:id` - Get specific post
- `PUT /api/v1/posts/:id` - Update post
- `DELETE /api/v1/posts/:id` - Delete post

### **Users API**
- `GET /api/v1/users` - List users
- `GET /api/v1/users/:id` - Get user profile
- `GET /api/v1/users/:id/activities` - User activities
- `GET /api/v1/users/:id/posts` - User posts

## 📋 Requirements

- **Ruby 3.4.5+**
- **Rails 7.1.0+** 
- **SQLite3** (development)
- **PostgreSQL 14+** (production recommended)
- **Node.js** (for asset compilation)
- **Git** (version control)

## 🔒 Security Features

- **CSRF Protection** - Cross-site request forgery protection
- **SQL Injection Prevention** - Parameterized queries and Active Record
- **XSS Protection** - HTML sanitization and content security
- **Session Security** - Secure session management with timeout
- **Password Security** - bcrypt encryption with secure policies
- **Activity Logging** - Comprehensive audit trail
- **Role-Based Access** - Granular permission system

## 🚀 Deployment

This application is production-ready and can be deployed to various platforms:

- **Heroku** - Easy deployment with PostgreSQL addon
- **AWS** - EC2, RDS, and S3 integration ready
- **Docker** - Containerization support available
- **VPS** - Traditional server deployment

See [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) for detailed deployment instructions.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## � Support

For support, bug reports, or feature requests:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

---

**For complete technical documentation, API references, deployment guides, and advanced configuration, see [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)**

*Built with ❤️ By Sanjana Devi using Ruby on Rails*
