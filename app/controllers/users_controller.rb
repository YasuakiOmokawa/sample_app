class UsersController < ApplicationController

  require 'holiday_japan'
  require 'user_func'
  require 'create_table'
  require 'insert_table'
  require 'update_table'
  require 'securerandom'
  require "retryable"
  include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils, ExcelFunc

  before_action :signed_in_user, only: [
    :index,
    :edit,
    :update,
    :destroy,
    :show,
    :edit_init_analyze,
    :update_init_analyze
  ]
  before_action :correct_user,   only: [
    :show,
    :edit,
    :update,
    :edit_init_analyze,
    :update_init_analyze
  ]
  before_action :admin_user,      only: [:destroy, :show_detail, :edit_detail, :update_detail, :new]
  before_action :create_common_table, only: [:detail]
  before_action :create_home, only: [:home_anlyz]
  prepend_before_action :chk_param, only: [:home_anlyz, :get_filter_keywords, :detail]

  def get_filter_keywords

    logger.info( "絞り込み条件用のキーワードを取得します")

    add_category_condition(params[:category])

    @cv_txt = ('goal' + @cv_num.to_s + '_completions')
    kwds = []
    case params[:category]
    when 'referral'
      special = :source
      ref_source = Ast::Ganalytics::Garbs::Data.create_class('Ref',
        [ :sessions], [special] ).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).res)
      ref_source.each do |t|
        kwds.push('r' + t.source)
      end
    when 'social'
      special = :socialNetwork
      soc_source = Ast::Ganalytics::Garbs::Data.create_class('Soc',
        [ :sessions], [special] ).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).res)
      soc_source.each do |t|
        kwds.push( 'l' + t.social_network)
      end
    end

    logger.info( "絞り込み条件用のキーワードを取得しました")

    # キーワード配列を返却
    render json: {
      :keywords => kwds.to_json,
    }
  end

  def cache_result_anlyz
    if params[:result_obj].present? && params[:cache_key].present?

      logger.info( '分析結果の上位15位をキャッシュします。')
      Rails.cache.write(params[:cache_key],
        params[:result_obj].to_s, expires_in: 1.hour, compress: true)
    end
    render json: { cache_result: "ok"}
  end

  def chk_cache
    if Rails.cache.read(params[:for_get_request])
      render json: { is_cached: true}
    else
      render json: { is_cached: false}
    end
  end

  def home_anlyz
    render json: {
      :homearr => @json,
      :device_filter => @device_filter,
      :user_filter => @user_filter,
      :keyword_filter => @keyword_filter,
    }
  end

  def detail
    @partial = 'detail'

    unless request.wiselinks_partial?
      render action: 'show', layout: 'ganalytics'
    end
  end

  def index
    render :layout => false, :text => "管理者権限をもつユーザでログインしてください" unless current_user.admin?
    @users = User.all
  end

  def show
    @partial = 'show'

    if request.query_string.present?
      gon.cached_item = JSON.parse(
        Rails.cache.read(request.query_string))
      gon.cached_from = params[:from]
      gon.cached_to = params[:to]
    end

    unless request.wiselinks_partial?
      render layout: 'ganalytics'
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "ユーザを登録しました！"
      redirect_to users_path
    else
      render 'new'
    end
  end

  def edit
    render :layout => 'not_ga'
  end

  def edit_init_analyze
    get_ga_profiles
    render :layout => 'not_ga'
  end

  def edit_detail
    @user = User.find(params[:id])
  end

  def update
      if @user.update_attributes(user_params)
        redirect_to @user
      else
        render 'edit', :layout => 'not_ga'
      end
  end

  def update_init_analyze
      if @user.update_columns(user_params)
        flash[:success] = "Profile updated"
        redirect_to @user
      else
        render 'edit_analyze_prof', :layout => false
      end
  end

  def update_detail
      @user = User.find(params[:id])
      if @user.update_attributes(user_params)
        flash[:success] = "Profile updated"
        redirect_to users_path
      else
        render 'edit_detail'
      end
  end

  def destroy
      User.find(params[:id]).destroy
      flash[:success] = "ユーザーを削除しました。"
      redirect_to users_url
  end

  def show_detail
      @user = User.find(params[:id])
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation, :gaproperty_id,
                                   :gaprofile_id, :gaproject_id, :init_cv_num)
    end

    # Before actions
    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def chk_param

      @content = begin Content.find(params[:cv_num]) rescue nil end
      @content.upload_file.shift unless @content.nil?
      (@from, @to) = set_from_to(@content, params)

      # ajaxリクエストの判定
      # chk_cache

      # パラメータ共通設定
      @user = User.find(params[:id])
      get_ga_profiles
      @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
      # 分析カテゴリ
      set_action(params[:category], @cond)
      # 使用端末
      set_device_type(params[:devfltr], @cond)
      # 来訪者
      set_visitor_type(params[:usrfltr], @cond)
      #　グラフ表示項目
      @graphic_item  = (params[:metrics].presence || 'pageviews').to_sym
      # CV種類
      @cv_num = (@content.nil? ? params[:cv_num] : '1').to_i
      # 絞り込みキーワードの指定
      if params[:kwdfltr]
        narrow_tag = params[:kwdfltr][-1]
        params[:kwdfltr].slice!(-1);
        set_narrow_word(params[:kwdfltr], @cond, narrow_tag)
      end
      # 日付タイプを設定
      @day_type = params[:dayType].presence || 'all_day'
      Rails.logger.info("@cond setting is #{@cond}")
    end

    def create_common_table

      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')

      metrics = Metrics.new()
      metrics_camel_case_datas = metrics.garb_parameter
      metrics_snake_case_datas = metrics.garb_result
      metrics_for_graph_merge = metrics.jp_caption

      ### APIデータ取得部

      # リトライ時のメッセージを指定
      exception_cb = Proc.new do |retries|
        logger.info("API request retry: #{retries}")
      end

      ### APIデータ取得部（詳細グラフ用）
      cls_name = 'SiteData'
      # 4回までリトライできます
      site_data = Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        Ast::Ganalytics::Garbs::Data.create_class(cls_name,
          metrics_camel_case_datas.dup.push([ (@cv_txt.classify + 's').to_sym]), [:date] ).results(@ga_profile, @cond)
      end

      # 人気ページ用
      cved_data = anlyz_sessions_per_page_and_date(@cond)
      for_all_cond = @cond.dup
      for_all_cond[:filters] = {}
      Rails.logger.info("for_all_cond is #{for_all_cond}")
      all_data = anlyz_sessions_per_page(for_all_cond)

      ### データ計算部
      @ast_data = site_data.reduce([]) do |acum, item|
        item.day_type = chk_day(item.date.to_date)
        item.repeat_rate = item.sessions.to_i > 0 ? (100 - item.percent_new_sessions.to_f).round(1).to_s : "0"
        acum << item
      end

      # カスタムデータ置き変え判定
      replace_cv_with_custom(@content, @ast_data, @cv_txt)

      # グラフ表示プログラムへ渡すデータを作成
      gon.data_for_graph_display = create_data_for_graph_display(@ast_data, @graphic_item)

      # 人気ページ
      # 日付種別の追加
      favorites = cved_data.reduce([]) do | acum, item |
        item.day_type = chk_day(item.date.to_date)
        acum << item
      end

      @favorites = metrics_for_validate(
        favorites, @day_type, :sessions).get_metrics_per_page.reduce([]) do | acum, item |
        # CVデータ(目標値)に該当するall_sessions データが存在したらgap値計算を実施する
        all = all_data.results.select { | _all | _all.page_path == item.page_path }
        unless all.blank?
          item.present = all[0].sessions.to_i - item.sessions
          item.gap = item.sessions - item.present
          acum << item
        end
        acum
      end.sort_by{|item| -(item.gap.abs)}.first(10).reduce([]) do |acum, v|
        # GAP値の上位10位までを抽出
          acum << v
          acum
        end
      # 上位10位に満たない場合は空欄を埋める
      (10 - @favorites.size).times {
        os = OpenStruct.new
        os.page_path = '-'
        os.present = '-'
        os.sessions = '-'
        os.gap = '-'
        @favorites << os
      }
      Rails.logger.info("result @favorite data is #{@favorites}")

    end

    def create_home

      #　◆ページ先頭のバブルチャートを生成

      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      cv = @cv_txt

      # リクエストパラメータに応じてカテゴリを決定
      @category = add_category_condition(params[:category])
      # リクエストパラメータに応じてデバイスを絞る
      @device_filter = add_device_condition(params[:filter][:dev])
      # リクエストパラメータに応じて訪問者を絞る
      @user_filter = add_user_condition(params[:filter][:usr])
      # キーワードを設定する
      @keyword_filter = add_keyword_condition(params[:filter][:kwd])

      # データ集計
      p_hash = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

      # デバイス::訪問者::キーワード
      room = @device_filter + '::' + @user_filter + '::' + @keyword_filter

      # データ指標
      metrics = Metrics.new()
      metrics_camel_case_datas = metrics.garb_parameter
      @metrics_snake_case_datas = metrics.garb_result
      metrics_for_graph_merge = metrics.jp_caption

      # リトライ時のメッセージを指定
      exception_cb = Proc.new do |retries|
        logger.info("API request retry: #{retries}")
      end

      ### APIデータ取得部
      cls_name = 'SiteData'
      # 4回までリトライできます
      site_data = Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        Ast::Ganalytics::Garbs::Data.create_class(cls_name,
          metrics_camel_case_datas.dup.push([ (@cv_txt.classify + 's').to_sym]), [:date] ).results(@ga_profile, @cond)
      end

      ### 取得データ加工部
      @ast_data = site_data.reduce([]) do |acum, item|
        item.day_type = chk_day(item.date.to_date)
        item.repeat_rate = item.sessions.to_i > 0 ? (100 - item.percent_new_sessions.to_f).round(1).to_s : "0"
        acum << item
      end

      # カスタムデータ置き変え判定
      replace_cv_with_custom(@content, @ast_data, @cv_txt)

      # Rails.logger.info("CVの現在値は#{@ast_data}")

      # 分析データのバリデート
      logger.info("分析データのバリデートを開始します")

      @valid_analyze_day_types = get_day_types

      validate_cv
      if @valid_analyze_day_types.size == 0
        logger.info( "分析対象の日付がありません。処理を終了します。" )
        return
      end

      # 日付とメトリクスの組み合わせコレクションを作る
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create

      validate_metrics
      if @valids.map {|t| t.metricses.size}.sum == 0
        logger.info( "分析対象の指標データがありません。処理を終了します。" )
        return
      end

      logger.info("分析データのバリデートがすべて完了しました。分析を開始します")

      @valids.each do |valid|
        # バブルチャートに表示するデータを算出
        bubble_datas = generate_graph_data(@ast_data, valid.metricses, valid.day_type)
        # 目標値の算出
        calc_desire_datas(bubble_datas)
        d_hsh = metrics_day_type_jp_caption(valid.day_type, metrics_for_graph_merge)
        home_graph_data = concat_data_for_graph(bubble_datas, d_hsh)

        # ページ項目へ追加
        day_room = room +  '::' + valid.day_type
        p_hash[@category][day_room] = home_graph_data
        Rails.logger.info("#{@category} #{day_room} のデータセットが完了しました。")
      end

      # jqplot へデータ渡す
      @json = p_hash.to_json
    end
end
