class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      
      # Personal Information
      t.text :bio
      t.string :location
      t.string :city
      t.string :country
      t.string :timezone, default: 'UTC'
      t.date :birthday
      t.integer :age
      t.integer :gender, default: 0
      
      # Professional Information
      t.string :occupation
      t.string :company
      t.string :education
      t.integer :years_of_experience
      t.decimal :salary_range_min, precision: 10, scale: 2
      t.decimal :salary_range_max, precision: 10, scale: 2
      t.string :skills, array: true, default: []
      t.string :interests, array: true, default: []
      
      # Social Links
      t.string :website
      t.string :github_username
      t.string :linkedin_username
      t.string :twitter_username
      t.string :instagram_username
      t.string :facebook_username
      
      # Settings
      t.boolean :public, default: true
      t.boolean :show_email, default: false
      t.boolean :show_phone, default: false
      t.boolean :searchable, default: true
      t.integer :status, default: 0
      t.integer :theme_preference, default: 0
      t.integer :language, default: 0
      
      # Metrics
      t.integer :profile_views, default: 0
      t.integer :completion_percentage, default: 0
      
      # Additional fields
      t.json :social_links, default: {}
      t.json :preferences, default: {}
      t.json :custom_fields, default: {}
      
      t.timestamps
    end
    
    # Add indexes
    add_index :profiles, :public
    add_index :profiles, :searchable
    add_index :profiles, :status
    add_index :profiles, :occupation
    add_index :profiles, :company
    add_index :profiles, :country
    add_index :profiles, :skills, using: 'gin'
    add_index :profiles, :interests, using: 'gin'
  end
end
