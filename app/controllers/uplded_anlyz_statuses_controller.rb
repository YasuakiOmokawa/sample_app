class UpldedAnlyzStatusesController < ApplicationController

  def update
    uplded_anlyz_status = UpldedAnlyzStatus.find_or_initialize_by(
      user_id: params[:id])
    content_id = uplded_anlyz_status_params[:content_id]
    permits = {}
    unless content_id.nil?
      permits[:active] = true
      permits[:content_id] = content_id
    end

    if uplded_anlyz_status.update_attributes(permits)
      render nothing: true,
        status: 200
    else
      render json: {errors: uplded_anlyz_status.errors.messages},
        status: 422
    end
  end

  private

    def uplded_anlyz_status_params
      params.require(:uplded_anlyz_status).permit(:content_id)
    end

end
