module UpldedAnlyzStatusesHelper

  def active_content(id)
    ul = UpldedAnlyzStatus.active(id).first
    Content.find(ul.content_id) unless ul.nil?
  end
end
