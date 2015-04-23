require('csv')

class Content < ActiveRecord::Base

  # シリアライズ対象
  serialize :upload_file

  validates :upload_file, presence: true
  validates :user_id, presence: true

  # カスタムバリデーション
  validates :upload_file, csv: true


end
