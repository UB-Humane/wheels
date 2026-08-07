class AddCodenameToBikeRequests < ActiveRecord::Migration[8.1]
  def up
    add_column :bike_requests, :codename, :string

    BikeRequest.reset_column_information
    BikeRequest.find_each do |bike_request|
      bike_request.update_column(:codename, BikeRequest.generate_codename)
    end

    change_column_null :bike_requests, :codename, false
    add_index :bike_requests, :codename
  end

  def down
    remove_column :bike_requests, :codename
  end
end
