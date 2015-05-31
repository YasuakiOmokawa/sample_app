class ChangeColumnToGaproject < ActiveRecord::Migration
  def change
    change_table :gaprojects do |t|

      # add
      t.column :oauth2_access_token, :string
      t.column :oauth2_refresh_token, :string
      t.column :oauth2_expires_at, :string
      t.column :oauth2_client_id, :string
      t.column :oauth2_client_secret, :string
      t.column :oauth2_scope, :string

      # remove
      t.remove :api_key, :proj_owner_email, :proj_owner_password
    end
  end
end
