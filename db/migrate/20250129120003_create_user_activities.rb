class CreateUserActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :user_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trackable, polymorphic: true, optional: true
      
      t.integer :activity_type, null: false
      t.string :description, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :city
      t.string :country
      t.json :metadata, default: {}
      
      t.timestamps
    end
    
    # Add indexes
    add_index :user_activities, :activity_type
    add_index :user_activities, :created_at
    add_index :user_activities, [:user_id, :created_at]
    add_index :user_activities, [:trackable_type, :trackable_id]
    add_index :user_activities, :ip_address
  end
end
