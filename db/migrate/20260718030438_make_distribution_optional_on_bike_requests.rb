class MakeDistributionOptionalOnBikeRequests < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bike_requests, :distribution_id, true
  end
end
