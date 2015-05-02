class UpldedAnlyzStatusesController < ApplicationController

  before_action :signed_in_user, only: [:active, :inactive]
  before_action :correct_user, only: [:active, :inactive]

  def active
    uplded_anlyz_status = UpldedAnlyzStatus.find_or_initialize_by(
      user_id: params[:id])
    content_id = uplded_anlyz_status_params[:content_id]
    permits = {}
    unless content_id.nil?
      permits[:active] = true
      permits[:content_id] = content_id
    end

    if uplded_anlyz_status.update_attributes(permits)
      content = Content.find(content_id)
      content.upload_file.shift
      from = content.upload_file.first[0]
      to = content.upload_file.last[0]
      render json: {
          from: from,
          to: to,
          content_id: content.id,
          upload_file_name: content.upload_file_name
        }, status: 200
    else
      render json: {errors: uplded_anlyz_status.errors.messages},
        status: 422
    end
  end

  def inactive
    uplded_anlyz_status = UpldedAnlyzStatus.where(
      content_id: uplded_anlyz_status_params[:content_id],
      user_id: params[:id], active: true).first
    unless uplded_anlyz_status.nil?
      uplded_anlyz_status.update_attributes(active: false)
      Rails.logger.info('カスタム解析が解除されました')
    end
    render nothing: true, status: 200
  end

  private

    def uplded_anlyz_status_params
      params.require(:uplded_anlyz_status).permit(:content_id)
    end

end
