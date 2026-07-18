class RemoveAnyBikeType < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE bikes SET bike_type = 1 WHERE bike_type = 0"
    change_column_default :bikes, :bike_type, from: 0, to: 1
  end

  def down
    change_column_default :bikes, :bike_type, from: 1, to: 0
  end
end
