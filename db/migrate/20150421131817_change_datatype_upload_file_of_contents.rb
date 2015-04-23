class ChangeDatatypeUploadFileOfContents < ActiveRecord::Migration
  def change
    change_column :contents, :upload_file, :text
  end
end
