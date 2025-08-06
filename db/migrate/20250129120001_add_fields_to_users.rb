class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :username, :string
    add_column :users, :bio, :text
    add_column :users, :location, :string
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
    add_column :users, :phone, :string
    add_column :users, :active, :boolean, default: true
    add_column :users, :last_seen_at, :datetime
    add_column :users, :slug, :string
    add_column :users, :notification_preferences, :json, default: {}
    
    # Devise trackable fields
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
    
    # Devise confirmable fields
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    
    # Devise timeoutable
    add_column :users, :timeout_in, :integer
    
    # Add indexes
    add_index :users, :username, unique: true
    add_index :users, :slug, unique: true
    add_index :users, :last_seen_at
    add_index :users, :active
    add_index :users, :confirmation_token, unique: true
    add_index :users, [:latitude, :longitude]
  end
end
