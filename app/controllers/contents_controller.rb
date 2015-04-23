class ContentsController < ApplicationController

  before_action :signed_in_user, only: [:show]
  before_action :correct_user, only: [:show]
  before_action :chk_file, only: [:create]

  def show
    @content ||= Content.new
    render :layout => 'not_ga'
  end

  def create
    @tmp_content[:upload_file] = @testfile
    @content = Content.new(@tmp_content)
    if @content.save
      flash[:success] = "アップロード成功"
      redirect_to(root_path)
    else
      render 'contents/show', :layout => 'not_ga'
    end
  end

  private

    def chk_file
      @user = User.find(params[:content][:user_id])
      upload_file = content_params[:upload_file]
      @tmp_content = {}
      if upload_file != nil
        @tmp_content[:upload_file_name] = upload_file.original_filename
        @tmp_content[:user_id] = content_params[:user_id]
        begin
          @testfile = CSV.read(upload_file.tempfile, {col_sep: "\t"})
        rescue => e
          @tmp_content[:upload_file] = 'hoge'
          @content = Content.new(@tmp_content)
          @content.errors[:base] << "TSV形式のファイルを選択してください"
          @content.errors.add(:upload_file, e)
          render 'contents/show', :layout => 'not_ga'
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def content_params
      params.require(:content).permit(:upload_file, :user_id)
    end
end
