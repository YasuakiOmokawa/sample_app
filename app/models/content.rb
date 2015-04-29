require('csv')

class Content < ActiveRecord::Base

  # シリアライズ対象
  serialize :upload_file

  validates :upload_file, presence: true
  # カスタムバリデーション
  validates :upload_file, csv: true, :allow_nil => true

  def present?
    self.user_id.present?
  end

end
