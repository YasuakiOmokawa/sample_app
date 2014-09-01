class ChangeTableToGaprojects < ActiveRecord::Migration
  def change
    change_table :gaprojects do |t|
      t.column :proj_owner_email, :string
      t.column :proj_owner_password, :string
    end

  end
end
