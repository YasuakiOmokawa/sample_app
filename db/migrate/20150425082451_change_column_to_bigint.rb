class ChangeColumnToBigint < ActiveRecord::Migration
  def change
    change_column :uplded_anlyz_statuses, :id, :integer, limit: 4
    change_column :uplded_anlyz_statuses, :content_id, :integer, limit: 8
    change_column :contents, :id, :integer, limit: 8
  end
end
