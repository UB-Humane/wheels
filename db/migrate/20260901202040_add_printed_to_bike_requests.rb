class AddPrintedToBikeRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :bike_requests, :printed, :boolean, default: false, null: false
  end
end
