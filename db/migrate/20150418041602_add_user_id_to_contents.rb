class AddUserIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :user_id, :integer
    add_column :contents, :active, :boolean
    add_index "contents", ["user_id"], name: "index_contents_on_user_id", using: :btree
  end
end
