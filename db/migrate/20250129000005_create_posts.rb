class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false, limit: 100
      t.text :body, null: false
      t.integer :status, default: 0, null: false
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Indexes for performance
    add_index :posts, :slug, unique: true
    add_index :posts, :status
    add_index :posts, [:user_id, :status]
    add_index :posts, [:status, :created_at]
  end
end
