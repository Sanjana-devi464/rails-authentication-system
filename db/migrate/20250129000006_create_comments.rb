class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.text :content, null: false
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Indexes for performance
    add_index :comments, [:post_id, :created_at]
    add_index :comments, [:user_id, :created_at]
  end
end
