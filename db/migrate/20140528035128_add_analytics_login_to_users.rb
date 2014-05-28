class AddAnalyticsLoginToUsers < ActiveRecord::Migration
  def change
        add_column :users, :analytics_email, :string
        add_column :users, :analytics_password, :string
  end
end
