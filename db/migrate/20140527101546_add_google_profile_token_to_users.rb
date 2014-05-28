class AddGoogleProfileTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :property_id, :string
    add_column :users, :profile_id, :string
  end
end
