class CreateUpldedAnlyzStatuses < ActiveRecord::Migration
  def change
    create_table :uplded_anlyz_statuses do |t|

      t.integer  "user_id", null: false
      t.boolean  "active", default: false
      t.integer "content_id", null: false
      t.timestamps null: false
    end
    add_index :uplded_anlyz_statuses, :user_id, :unique => true
  end
end
