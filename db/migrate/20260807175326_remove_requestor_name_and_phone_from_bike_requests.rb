class RemoveRequestorNameAndPhoneFromBikeRequests < ActiveRecord::Migration[8.1]
  def change
    remove_column :bike_requests, :requestor_name, :string, null: false
    remove_column :bike_requests, :phone, :string, null: false
  end
end
