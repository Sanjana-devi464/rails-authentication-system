class RemoveCompletionPercentageFromProfiles < ActiveRecord::Migration[7.1]
  def change
    remove_column :profiles, :completion_percentage, :integer
  end
end
