require 'user_func'

class ContentsController < ApplicationController
  include ParamUtils

  before_action :signed_in_user, only: [:show, :destroy]
  before_action :correct_user, only: [:show, :destroy]
  before_action :chk_file, only: [:create]

  Oauths = Struct.new(:oauth2, :user_data)

  def redirect
    redirect_to user_url
  end

  def show
   @partial = 'contents/show'

    @content ||= Content.new

    get_ga_goal

    # binding.pry
    cachable_referer?(request.referer)

    if request.wiselinks_partial?
      render template: 'users/show'
    else
      render template: 'users/show', layout: 'ganalytics'
    end
  end

  def create
    @tmp_content[:upload_file] = @testfile
    @content = Content.new(@tmp_content)
    if @content.save
      @content.upload_file.shift
      render json: {
        from: padding_date_format( @content.upload_file.first[0] ),
        to: padding_date_format( @content.upload_file.last[0] ),
        cv_num: @content.id.to_s,
        cv_name: @content.upload_file_name.split('.').first.truncate(10),
      }, status: 200
    else
      render json: {errors: @content.errors.messages},
        status: 422
    end
  end

  def destroy
  end

  private

    def cachable_referer?(ref)
      # 他サイトからのリンク経由や、設定画面の直リンクで流入した場合は
      # 設定後にホーム画面に戻す
      if ref.match(/#{request.domain}/) && ( not ref.match(/signin/) )
        Rails.cache.write(setting_referrer_key, request.referer,
          expires_in: 0, compress: true)
      end unless ref.nil?
    end

    def setting_referrer_key
      "setting_referrer_user_id_#{current_user.id}"
    end

    def get_ga_goal
      oauth2 = Ast::Ganalytics::Garbs::GoogleOauth2InstalledCustom.new(current_user.gaproject)
      gaservice = Ast::Ganalytics::Garbs::Session.new(Oauths.new(oauth2, current_user))
      @ga_goals = Rails.cache.fetch("oauthed_user_id_#{current_user.id}", expires_in: 30.minutes) do
        gaservice.get_goal       # アナリティクスに設定されているCV一覧
      end
      gon.ga_goals = @ga_goals.size
    end

    def chk_file
      @partial = 'contents/show'
      get_ga_goal
      @storage_key = Rails.cache.read(setting_referrer_key).presence || user_url

      # binding.pry
      upload_file = content_params[:upload_file].presence
      @tmp_content = {}
      if upload_file.nil? && content_params[:date] && content_params[:cv_num] != 'file'
        (from, to) = content_params[:date].split(' - ')
        render json: {
          from: from,
          to: to,
          cv_num: content_params[:cv_num],
          cv_name: @ga_goals.key(content_params[:cv_num]).truncate(10),
        }, status: 200
      elsif upload_file
        @tmp_content[:upload_file_name] = upload_file.original_filename
        @tmp_content[:user_id] = current_user.id
        begin
          @testfile = CSV.read(upload_file.tempfile)
        rescue => e
          @tmp_content[:upload_file] = 'hoge'
          @content = Content.new(@tmp_content)
          @content.errors[:base] << "ファイル形式が間違っています"
          @content.errors.add(:upload_file, e)
          render json: {errors: @content.errors.messages},
            status: 422
        end
      end

    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def content_params
      params.require(:content).permit(:id, :upload_file, :user_id, :date, :cv_num)
    end
end
