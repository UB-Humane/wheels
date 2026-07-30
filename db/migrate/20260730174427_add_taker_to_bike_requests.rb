class AddTakerToBikeRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :bike_requests, :taker, foreign_key: { to_table: :users }, null: true, index: true
  end
end
