class ChangeTableToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.column :gaproject_id, :integer
      t.rename :property_id, :gaproperty_id
      t.rename :profile_id, :gaprofile_id
      t.remove :analytics_email, :analytics_password, :apikey
    end
  end
end
