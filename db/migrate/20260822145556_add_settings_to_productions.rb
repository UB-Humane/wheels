class AddSettingsToProductions < ActiveRecord::Migration[8.1]
  def change
    add_column :productions, :settings, :jsonb, null: false, default: {
      print_padding_top: 120, print_padding_right: 20, print_padding_bottom: 20, print_padding_left: 20
    }
  end
end
