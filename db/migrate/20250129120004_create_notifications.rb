class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, optional: true, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, optional: true
      
      t.integer :notification_type, null: false
      t.integer :priority, default: 1
      t.string :title, null: false
      t.text :message, null: false
      t.string :url
      t.datetime :read_at
      t.json :metadata, default: {}
      
      t.timestamps
    end
    
    # Add indexes
    add_index :notifications, :notification_type
    add_index :notifications, :priority
    add_index :notifications, :read_at
    add_index :notifications, :created_at
    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
