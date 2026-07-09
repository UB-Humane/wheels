class ChangeDefaultBikeRequestStatusToRequested < ActiveRecord::Migration[8.1]
  def change
    change_column_default :bike_requests, :status, from: 0, to: 1
  end
end
