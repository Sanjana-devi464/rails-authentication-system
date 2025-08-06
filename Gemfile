source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.5"

# Core Rails (avoiding problematic gems)
gem "rails", "~> 7.1.0"

# Web server
gem "puma", "~> 6.0"

# Basic functionality
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "sprockets-rails"

# Fix for fiddle deprecation warning
gem "fiddle"

# Database
gem "sqlite3", "~> 1.4"

# Authentication
gem "devise"

# Role management
gem "rolify"

# Authorization
gem "cancancan"

# Tagging system
gem "acts-as-taggable-on"

# SEO-friendly URLs
gem "friendly_id"

# Geocoding
gem "geocoder"

# Search functionality
gem "ransack"

# Pagination
gem "kaminari"

# Message pack for serialization
gem "msgpack", ">= 1.7.0"

# SEO meta tags
gem "meta-tags"

# OAuth and HTTP gems
gem "oauth2"
gem "net-http"
gem "uri"
gem "json"

# Windows specific
gem "tzinfo-data", platforms: %i[ windows ]

# Development group
group :development do
  gem "web-console"
end
