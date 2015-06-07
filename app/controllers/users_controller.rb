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
    :all,
    :search,
    :direct,
    :referral,
    :social,
    :edit_init_analyze,
    :update_init_analyze
  ]
  before_action :correct_user,   only: [
    :show,
    :all,
    :search,
    :direct,
    :referral,
    :social,
    :edit,
    :update,
    :edit_init_analyze,
    :update_init_analyze
  ]
  before_action :admin_user,      only: [:destroy, :show_detail, :edit_detail, :update_detail, :new]
  before_action :create_common_table, only: [:all, :search, :direct, :referral, :social, :campaign]
  before_action :create_home, only: [:show]
  prepend_before_action :chk_param, only: [:show, :all, :search, :direct, :referral, :social, :campaign]

  def social
    # パラメータ個別設定
    @title = 'ソーシャル'
    @narrow_action = social_user_path
    @details_partial = 'details'
    gon.div_page_tab = 'social'

    special = :socialNetwork
    @in_table = res_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    @categories = []
    special_for_garb = to_garb_attr(special)
    # データ取得部
    session_rank = get_session_rank(special)
    if session_rank.total_results == 0
      Rails.logger.info("#{@title} の参照元は非分析対象です")
      render :layout => 'ganalytics', :action => 'show' and return
    end
    session_data = get_session_data(special)

    # 計算部
    changed_kwds = change_to_garb_kwds(session_rank,
      special_for_garb)

    changed_kwds.each do |kwd|
      Rails.logger.info("#{kwd} のソーシャルバリデートを実施します")
      reduce = reduce_with_kwd(session_data,
        kwd, special_for_garb)

      # カスタムデータ置き換え判定
      replace_cv_with_custom(@content, reduce, @cv_txt)

      # バリデートデータの準備
      cves = cves_for_validate(reduce, @day_type)
      df = metrics_for_validate(reduce, @day_type, :sessions)
      #CVバリデート
      unless is_not_uniq?(cves)
        validate_cv_msg(@day_type)
        next
      end
      #メトリクスバリデート
      unless is_not_uniq?(df.get_metrics)
         validate_uniq_metrics_msg(:sessions)
         next
      end
      unless cves.zip(df.get_metrics).uniq.size >= 3
        validate_invalid_metrics_multiple_msg(:sessions)
        next
      end
      if ExcelFunc.excel_upper_quartile(df.get_metrics) == 0
        validate_too_much_zero_metrics_msg(:sessions)
        next
      end

      Rails.logger.info("#{kwd} のソーシャルバリデートに成功しました")

      # 相関分析開始
      res_table[kwd] = generate_graph_data(reduce,
          [:sessions], @day_type)[komoku_day_type(:sessions, @day_type)]
    end

    calc_desire_datas(res_table)
    @in_table = head_special(res_table, 3)     # 相関係数の高い順にソート
    create_listbox_categories('l')

    render :layout => 'ganalytics', :action => 'show'
  end

  def referral
    # パラメータ個別設定
    @title = 'その他ウェブサイト'
    @narrow_action = referral_user_path
    @details_partial = 'details'
    gon.div_page_tab = 'referral'

    special = :source
    @in_table = res_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    @categories = []
    special_for_garb = to_garb_attr(special)
    # データ取得部
    session_rank = get_session_rank(special)
    if session_rank.total_results == 0
      Rails.logger.info("#{@title} の参照元は非分析対象です")
      render :layout => 'ganalytics', :action => 'show' and return
    end
    session_data = get_session_data(special)

    # 計算部
    changed_kwds = change_to_garb_kwds(session_rank,
      special_for_garb)

    changed_kwds.each do |kwd|
      Rails.logger.info("#{kwd} の参照バリデートを実施します")
      reduce = reduce_with_kwd(session_data,
        kwd, special_for_garb)

      # カスタムデータ置き換え判定
      replace_cv_with_custom(@content, reduce, @cv_txt)

      # バリデートデータの準備
      cves = cves_for_validate(reduce, @day_type)
      df = metrics_for_validate(reduce, @day_type, :sessions)
      #CVバリデート
      unless is_not_uniq?(cves)
        validate_cv_msg(@day_type)
        next
      end
      #メトリクスバリデート
      unless is_not_uniq?(df.get_metrics)
         validate_uniq_metrics_msg(:sessions)
         next
      end
      unless cves.zip(df.get_metrics).uniq.size >= 3
        validate_invalid_metrics_multiple_msg(:sessions)
        next
      end
      if ExcelFunc.excel_upper_quartile(df.get_metrics) == 0
        validate_too_much_zero_metrics_msg(:sessions)
        next
      end

      Rails.logger.info("#{kwd} の参照バリデートに成功しました")

      # 相関分析開始
      res_table[kwd] = generate_graph_data(reduce,
          [:sessions], @day_type)[komoku_day_type(:sessions, @day_type)]
    end

    calc_desire_datas(res_table)
    @in_table = head_special(res_table, 3)     # 相関係数の高い順にソート
    create_listbox_categories('r')

    render :layout => 'ganalytics', :action => 'show'
  end

  def direct
    @title = '直接入力/ブックマーク'
    @narrow_action = direct_user_path
    gon.div_page_tab = 'direct'
    @details_partial = 'norender'

    render :layout => 'ganalytics', :action => 'show'
  end

  def search
    @title = '検索'
    @narrow_action = search_user_path
    gon.div_page_tab = 'search'
    @details_partial = 'norender'

    render :layout => 'ganalytics', :action => 'show'
  end

  def index
    render :layout => false, :text => "管理者権限をもつユーザでログインしてください" unless current_user.admin?
    @users = User.all
  end

  def first
    # ホーム画面pjax用
    @title = 'ホーム'
    @partial = 'first'   # ページ毎の部分テンプレート
    @tests = %w(まどか さやか ほむら マミ 杏子)
    unless request.wiselinks_partial?
      render layout: 'ganalytics', action: 'show'
    end
  end

  def show
    # パラメータ個別設定
    @title = 'ホーム'
    @narrow_action = user_path
    gon.narrow_action = user_path
    @partial = 'first'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'first'

    # テンプレート検証用
    @tests = %w(hoge fuga gogo)

    render json: {
      :homearr => @json,
      :page_fltr_wd => @page_fltr_wd,
      :page_fltr_dev => @page_fltr_dev,
      :page_fltr_usr => @page_fltr_usr,
      :page_fltr_kwd => @page_fltr_kwd
    } and return if request.xhr?

    render :layout => 'ganalytics' and return
  end

  def all
    @title = '全体'
    @narrow_action = all_user_path
    @details_partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'all'

    render :layout => 'ganalytics', :action => 'show'
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
        flash[:success] = "Profile updated"
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

    def chk_cache
      if request.xhr?

        @memcache_kwd_key = set_key_for_data_cache(request.fullpath.to_s, @content)

        logger.info('リクエストパラメータのフルパスは以下です。')
        logger.info(@memcache_kwd_key)

        cached_item = Rails.cache.read(@memcache_kwd_key)
        logger.info('キャッシュされたキーワードデータが読み込まれました。') unless cached_item.nil?

        # キャッシュ読み書き(バブル用データ)
        if params[:analyze_type].present?

          memcache_graph_key = set_key_for_data_cache(
            create_cache_key(params[:analyze_type].to_s),
            @content)

          if params[:r_obj].present?

            logger.info( 'グラフ用データをキャッシュします。')
            caching_graph_data = params[:r_obj].to_s

            Rails.cache.write(memcache_graph_key, caching_graph_data, expires_in: 1.hour, compress: true)

            # 分析完了メールを送信
            # unless analyze_type == 'kobetsu'
            #   user = User.find(params[:id])
            #   UserMailer.send_message_for_complete_analyze(user, @from, @to).deliver if user
            # end

            return
          else

            logger.info( 'キャッシュされたグラフデータを読み込みます。')
            cached_item = Rails.cache.read(memcache_graph_key)
          end
        end

        # キャッシュ済のデータがあればキャッシュを返却してコントローラを抜ける
        if cached_item.present?
          logger.info( 'キャッシュデータが読み込まれました。')
          @json = cached_item
          return
        else
          logger.info( 'リクエストされたキーに紐づいているキャッシュデータはありません。')
        end
      end
    end

    def chk_param

      @content = UpldedAnlyzStatusesController.helpers.active_content(params[:id])
      @content.upload_file.shift unless @content.nil?
      (@from, @to) = set_from_to(@content, params)

      # ajaxリクエストの判定
      chk_cache

      # パラメータ共通設定
      @user = User.find(params[:id])
      get_ga_profiles
     @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
     set_action(params[:action], @cond)
      gon.radio_device = set_device_type( (params[:device].presence || "all"),@cond)                               # 使用端末
      gon.radio_visitor = set_visitor_type( (params[:visitor].presence || "all"),@cond)                                 # 来訪者
      #　グラフ表示項目
     @graphic_item  = (params[:graphic_item].presence || 'pageviews').to_sym
      #　赤で強調表示項目
     gon.red_item  = (params[:red_item].presence || '')
     gon.graphic_item = @graphic_item.to_s
     gon.format_string = check_format_graph(@graphic_item)
     # CV種類
     gon.cv_num = @cv_num = (params[:cv_num].presence || @user.init_cv_num).to_i
      # 絞り込みキーワード
      @narrow_word = params[:narrow_select].presence
      if params[:narrow_select].present?
        gon.narrow_word = params[:narrow_select].dup
        @narrow_tag = params[:narrow_select][-1]
        @narrow_word.slice!(-1)
        set_narrow_word(@narrow_word, @cond, @narrow_tag) # 絞り込んだキーワード
      end
      # 絞り込みセレクトボックス
      @categories = []

      # 日付タイプを設定
      @day_type = params[:day_type].presence || 'all_day'
      gon.radio_day = @day_type

      # ホーム画面の日付、cv名, hashを保存
      gon.history_from = params[:history_from].presence
      gon.history_to = params[:history_to].presence
      gon.history_cv_num = params[:history_cv_num].presence
      gon.history_hash = params[:hash].presence

      # ユーザーがアップロードした分析用ファイル
      @contents = ContentsController.helpers.get_users_contents(@user.id)
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

      ### APIデータ取得部
      cls_name = 'SiteData'
      # 4回までリトライできます
      site_data = Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        Ast::Ganalytics::Garbs::Data.create_class(cls_name,
          metrics_camel_case_datas.dup.push([ (@cv_txt.classify + 's').to_sym]), [:date] ).results(@ga_profile, @cond)
      end

      # 人気ページ用
      cved_data = Ast::Ganalytics::Garbs::Data.create_class('CvedSession',
        [:sessions], [:pagePath]).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).cved!.res)
      fav_gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).res, @cv_txt)
      fav_for_skel = Ast::Ganalytics::Garbs::Data::FetchKeywordForPages.results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).cved!.res)

      # ランディングページ用
      land_for_skel = Ast::Ganalytics::Garbs::Data::FetchKeywordForLanding.results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:bounceRate).res)

      # 全てのセッション(人気ページGAP値等計算用)
      ga_result = Ast::Ganalytics::Garbs::Data.create_class('AllSession', [:sessions], []).results(@ga_profile, @cond)
      tmp_all_session = ga_result.results.first.sessions.to_i if ga_result.total_results > 0
      all_session = guard_for_zero_division(tmp_all_session)

      ### データ計算部
      @ast_data = site_data.reduce([]) do |acum, item|
        item.day_type = chk_day(item.date.to_date)
        item.repeat_rate = item.sessions.to_i > 0 ? (100 - item.percent_new_sessions.to_f).round(1).to_s : "0"
        acum << item
      end

      # カスタムデータ置き変え判定
      replace_cv_with_custom(@content, @ast_data, @cv_txt)

      # グラフデータテーブルへ表示する指標値
      @desire_caption = metrics_for_graph_merge[@graphic_item][:jp_caption]

      # 指標値テーブルへ表示するデータを算出
      desire_datas = generate_graph_data(@ast_data, metrics_snake_case_datas, @day_type)
      desire_datas = create_common_skelton_table(metrics_snake_case_datas) if desire_datas.nil?
      calc_desire_datas(desire_datas) unless desire_datas.nil? # 目標値の算出

      # 日本語データを追加
      d_hsh = metrics_day_type_jp_caption(@day_type, metrics_for_graph_merge)
      @details_desire_datas = concat_data_for_graph(desire_datas, d_hsh) unless desire_datas.nil?

      # グラフ表示プログラムへ渡すデータを作成
      @data_for_graph_display = Hash.new{ |h,k| h[k] = {} }

      create_data_for_graph_display(@data_for_graph_display, @ast_data, @graphic_item, @cv_num)
      @data_for_graph_display = create_monthly_summary_data_for_graph_display(
        @data_for_graph_display, group_by_year_and_month(@ast_data),
        @graphic_item) if chk_monthly?(group_by_year_and_month(@ast_data)) == true
      gon.data_for_graph_display = @data_for_graph_display

      # グラフテーブルへ渡すデータを作成
      @data_for_graph_table = Hash.new{ |h,k| h[k] = {} }
      create_data_for_graph_display(@data_for_graph_table, @ast_data, @graphic_item, @cv_num)

      ## フォーマット変更

        # 目標値データへ
        @details_desire_datas.each do |k, v|
          change_format_for_desire(@details_desire_datas[k],
            check_format_graph(k).to_s, v)
        end unless @details_desire_datas.nil?

        # グラフテーブルへ
        @data_for_graph_table.each do |k, v|
          change_format_for_graph_table(@data_for_graph_table[k], check_format_graph(@graphic_item), v[0] )
        end

      # 人気ページテーブル
      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

      cved_session = cved_data.map{|t| t.sessions.to_f}.sum
      not_cved_session = all_session - cved_session

      create_skeleton_favorite_table(fav_for_skel, @favorite_table)
      put_favorite_table_for_skelton(fav_gap, @favorite_table)

      calc_percent_for_favorite_table(cved_session, @favorite_table, :good)
      calc_percent_for_favorite_table(not_cved_session, @favorite_table, :bad)
      calc_gap_for_favorite(@favorite_table)

      # ランディングページテーブル
      @landing_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      put_landing_table(land_for_skel, @landing_table)
    end

    def create_home

      #　◆ページ先頭のバブルチャートを生成

      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      cv = @cv_txt

      # ページ項目
      page = {
        'all' => {},
        'search' => {:medium.matches => 'organic'},
        'direct' => {:medium.matches => '(none)'},
        'referral' => {:medium.matches => 'referral'},
        'social' => {:has_social_source_referral.matches => 'Yes'},
      }

      # デバイス
      dev_opts = {
        'pc' => { :device_category.matches => 'desktop' },
        'sphone' => {
          :device_category.matches => 'mobile',
          :mobile_input_selector.matches => 'touchscreen'
        },
        'mobile' => {
         :device_category.matches => 'mobile',
          :mobile_input_selector.does_not_match => 'touchscreen'
        },
        'all' => {}
      }

      # 訪問者
      usr_opts = {
        'new' => {:user_type.matches => 'New Visitor'},
        'repeat' => { :user_type.matches => 'Returning Visitor' },
        'all' => {}
      }

      # 全体分析の完了したタイムスタンプを保持
      if params[:analyzeallcomplete].present?
        User.find(params[:id]).update_attribute(:limitanalyzeall, Time.now + 1.hour)
        return
      end

      # フラグで処理するか分ける
      shori = params[:shori].presence || 0
      if shori.to_i != 0

        # リクエストパラメータに応じてpageの項目を絞る
        wd = ' '
        if params[:act].present?
          wd = params[:act]
        else
          # 初期値はall
         wd = 'all'
        end
        @page_fltr_wd = wd
        page.select!{ |k,v| k == wd }

        # リクエストパラメータに応じてデバイスを絞る
        dev = ' '
        if params[:dev].present? and params[:dev] != 'undefined'
          dev = params[:dev]
        else
          # 初期値はall
          dev = 'all'
        end
        @page_fltr_dev = dev
        dev_opts.select!{ |k,v| k == dev }

        # リクエストパラメータに応じて訪問者を絞る
        usr = ' '
        if params[:usr].present? and params[:usr] != 'undefined'
          usr = params[:usr]
        else
          # 初期値はall
          usr = 'all'
        end
        @page_fltr_usr = usr
        usr_opts.select!{ |k,v| k == usr }

        # ページ項目の値に応じて絞り込みキーワードを選定する
        kwd = ''
        if params[:kwd].present?

          logger.info('パラメータで渡されたキーワード: ' + kwd)
          # キーワードがnokwdでない場合
          if params[:kwd].to_s != 'nokwd'

            kwd = params[:kwd].to_s
            p = kwd.slice!(0)

            set_narrow_word(kwd, @cond, p)
          else
            kwd = 'nokwd'
          end

        elsif kwd.empty?

          # キャッシュ済のデータがあればコントローラを抜ける
          return if @json.present?

          logger.info( "絞り込み条件が指定されていません。絞り込み条件を取得します")
          @cond[:filters].merge!(page.values[0])
          kwds = []
          case wd
          when 'referral'
            special = :source
            ref_source = Ast::Ganalytics::Garbs::Data.create_class('Ref',
              [ :sessions], [special] ).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(3).sort_desc!(:sessions).res)
            ref_source.each do |t|
              kwds.push('r' + t.source)
            end
          when 'social'
            special = :socialNetwork
            # データ取得部
            soc_source = Ast::Ganalytics::Garbs::Data.create_class('Soc',
              [ :sessions], [special] ).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(3).sort_desc!(:sessions).res)
            soc_source.each do |t|
              kwds.push( 'l' + t.social_network)
            end
          end
          @cond[:filters] = {}

          # キーワード配列を格納
          @json = kwds.to_json

          # 結果をキャッシュへ格納
          logger.info( "絞り込み条件を取得しました。キャッシュへ登録します。")
          Rails.cache.write(@memcache_kwd_key, @json, expires_in: 1.hour, compress: true)

          # コントローラを抜ける
          return
        end

        @page_fltr_kwd = kwd
        logger.info('設定されたキーワードは ' + kwd)

        # キャッシュ済のデータがあればコントローラを抜ける
        return if @json.present?

        # ページ項目ごとにデータ集計
        p_hash = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

        # 絞り込んだページ項目で、処理を開始
        page.each do |x, z|

          room = dev + '::' + usr + '::' + kwd           # デバイス::訪問者::キーワード

          # フィルタオプション追加（キーワードは追加済み）
          @cond[:filters].merge!(z)                            # ページ項目
          @cond[:filters].merge!(dev_opts[dev])       # デバイス
          @cond[:filters].merge!(usr_opts[usr])        # 訪問者

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

          # 分析データのバリデート
          logger.info("分析データのバリデートを開始します")

          @valid_analyze_day_types = get_day_types

          validate_cv
          if @valid_analyze_day_types.size == 0
            logger.info( "分析対象の日付がありません。処理を終了します。" )
            break
          end

          # 日付とメトリクスの組み合わせコレクションを作る
          @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create

          validate_metrics
          if @valids.map {|t| t.metricses.size}.sum == 0
            logger.info( "分析対象の指標データがありません。処理を終了します。" )
            break
          end

          logger.info("分析データのバリデートがすべて完了しました。分析を開始します")

          @valids.each do |valid|
            # バブルチャートに表示するデータを算出
            bubble_datas = generate_graph_data(@ast_data, valid.metricses, valid.day_type)
            d_hsh = metrics_day_type_jp_caption(valid.day_type, metrics_for_graph_merge)
            home_graph_data = concat_data_for_graph(bubble_datas, d_hsh)

            # ページ項目へ追加
            day_room = room +  '::' + valid.day_type
            p_hash[x][day_room] = home_graph_data
            Rails.logger.info("#{x} #{day_room} のデータセットが完了しました。")
          end
        end

        # ループ終了。jqplot へデータ渡す
        if shori != 0
          @json = p_hash.to_json
        end
      end
    end
end
