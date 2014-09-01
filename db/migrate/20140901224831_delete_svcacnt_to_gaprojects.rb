class DeleteSvcacntToGaprojects < ActiveRecord::Migration
  def change
    change_table :gaprojects do |t|
      t.remove :svc_acnt_key, :svc_acnt_email
    end
  end
end
