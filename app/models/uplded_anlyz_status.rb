class UpldedAnlyzStatus < ActiveRecord::Base

  validates :user_id, presence: true
  validates :content_id, presence: true

  scope :active, ->(id) { where(user_id: id, active: true) }

end
