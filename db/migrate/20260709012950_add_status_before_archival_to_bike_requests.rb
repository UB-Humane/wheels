class AddStatusBeforeArchivalToBikeRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :bike_requests, :status_before_archival, :integer
  end
end
