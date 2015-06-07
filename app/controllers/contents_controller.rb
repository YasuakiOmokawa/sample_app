class ContentsController < ApplicationController

  before_action :signed_in_user, only: [:show, :destroy]
  before_action :correct_user, only: [:show, :destroy]
  before_action :chk_file, only: [:create]

  Oauths = Struct.new(:oauth2, :user_data)

  def show
    # パラメータ個別設定
    @title = ApplicationController.helpers.full_title('設定')
    response.headers['X-Wiselinks-Title'] = URI.encode(@title)
    wiselinks_layout

    @content ||= Content.new

    oauth2 = Ast::Ganalytics::Garbs::GoogleOauth2InstalledCustom.new(current_user.gaproject)
    gaservice = Ast::Ganalytics::Garbs::Session.new(Oauths.new(oauth2, current_user))
    @ga_goals = Rails.cache.fetch("oauthed_user_id_#{current_user.id}", expires_in: 1.hour) do
      gaservice.get_goal       # アナリティクスに設定されているCV一覧
    end

    unless request.wiselinks_partial?
      render layout: 'ganalytics', template: 'users/show'
    end
  end

  def create
    @tmp_content[:upload_file] = @testfile
    @content = Content.new(@tmp_content)
    if @content.save
      flash[:notice] = "アップロードしました"
      redirect_to content_path(current_user)
    else
      render 'contents/show', :layout => 'not_ga'
    end
  end

  def destroy
    Content.find(params[:content_id]).destroy
    actives = UpldedAnlyzStatus.where(user_id: params[:id],
      content_id: params[:content_id], active: true).first
    actives.update_attributes(active: false) unless actives.nil?
    redirect_to content_path(current_user)
  end

  private

    def wiselinks_layout
      'ganalytics'
    end

    def chk_file
      # binding.pry
      upload_file = content_params[:upload_file] unless params[:content].nil?
      @tmp_content = {}
      unless upload_file.nil?
        @tmp_content[:upload_file_name] = upload_file.original_filename
        @tmp_content[:user_id] = current_user.id
        begin
          @testfile = CSV.read(upload_file.tempfile)
        rescue => e
          @tmp_content[:upload_file] = 'hoge'
          @content = Content.new(@tmp_content)
          @content.errors[:base] << "ファイル形式が間違っています"
          @content.errors.add(:upload_file, e)
          render 'contents/show', :layout => 'not_ga'
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def content_params
      params.require(:content).permit(:id, :upload_file, :user_id)
    end
end
