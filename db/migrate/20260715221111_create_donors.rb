class CreateDonors < ActiveRecord::Migration[8.1]
  def change
    create_table :donors do |t|
      t.references :production, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :mobile
      t.string :address
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
  end
end
