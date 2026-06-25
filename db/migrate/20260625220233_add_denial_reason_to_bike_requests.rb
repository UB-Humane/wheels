class AddDenialReasonToBikeRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :bike_requests, :denial_reason, :string
  end
end
