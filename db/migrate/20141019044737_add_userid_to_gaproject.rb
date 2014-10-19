class AddUseridToGaproject < ActiveRecord::Migration
  def change
    add_column :gaprojects, :userid, :integer
    add_index :gaprojects, :userid
  end
end
