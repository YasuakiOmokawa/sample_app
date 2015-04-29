module UpldedAnlyzStatusesHelper

  def active_content?
    ul = UpldedAnlyzStatus.active(params[:id]).first
    @content = Content.find(ul.content_id)
    render 
  end
end
