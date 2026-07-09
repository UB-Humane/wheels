class FixStatusSemanticsSwapRequestedAndPending < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE bike_requests SET status = 99 WHERE status = 0"
    execute "UPDATE bike_requests SET status = 0 WHERE status = 1"
    execute "UPDATE bike_requests SET status = 1 WHERE status = 99"
  end

  def down
    execute "UPDATE bike_requests SET status = 99 WHERE status = 1"
    execute "UPDATE bike_requests SET status = 1 WHERE status = 0"
    execute "UPDATE bike_requests SET status = 0 WHERE status = 99"
  end
end
