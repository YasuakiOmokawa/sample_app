class AddInitCvNumToUsers < ActiveRecord::Migration
  def change
    add_column :users, :init_cv_num, :integer, :default => 1
    User.update_all ["init_cv_num = ?",1]
  end
end
