class CreateGaprojects < ActiveRecord::Migration
  def change
    create_table :gaprojects do |t|
      t.string :proj_name
      t.text :svc_acnt_key
      t.text :svc_acnt_email
      t.string :api_key

      t.timestamps
    end
  end
end
