class UsersController < ApplicationController
  require 'holiday_japan'
  require 'user_func'
  require 'create_table'
  require 'insert_table'
  require 'update_table'
  require 'parallel'
  require 'securerandom'
  require "retryable"
  include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :show, :all, :search, :direct, :referral, :social, :campaign, :last]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy
  before_action :create_common_table, only: [:all, :search, :direct, :referral, :social, :campaign, :last]
  before_action :create_home, only: [:show]
  prepend_before_action :chk_param, only: [:show, :all, :search, :direct, :referral, :social, :campaign, :last]

  def last
    # パラメータ個別設定
    @title = 'カスタマイズ'
    @narrow_action = last_user_path
    @partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'last'

    render :layout => 'ganalytics'
  end

  def social
    # パラメータ個別設定
    @title = 'ソーシャル'
    @narrow_action = social_user_path
    @kitchen_partial = 'ref_and_social'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'social'

    # ページ個別設定
    # gap値の分処理が複雑
    dimend_key = :socialNetwork
    @social = Analytics.create_class('FetchKeywordForSoc',
        [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
    @rsc_table = create_skeleton_for_rsc(@social, dimend_key.to_s.to_snake_case)
    gap = fetch_analytics_data('FetchKeywordForSocial', @ga_profile, @cond, @cv_txt, {}, (@cv_txt.classify + 's').to_sym, dimend_key)
    put_rsc_table(@rsc_table, gap, @cv_txt, dimend_key.to_s.to_snake_case)
    calc_gap_for_common(@rsc_table)

    @categories["参照元"] = set_select_box(@social, 'l')

    @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
    @bedroom_partial = 'landing'
    @table_head = 'ソーシャル'

    render :layout => 'ganalytics', :action => 'show'
  end

  def referral
    # パラメータ個別設定
    @title = 'その他ウェブサイト'
    @narrow_action = referral_user_path
    @kitchen_partial = 'ref_and_social'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'referral'

    # ページ個別設定
    # gap値の分処理が複雑
    dimend_key = :source
    @referral = Analytics.create_class('FetchKeywordForRef',
        [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
    @rsc_table = create_skeleton_for_rsc(@referral, dimend_key.to_s.to_snake_case)
    gap = fetch_analytics_data('FetchKeywordForReferral', @ga_profile, @cond, @cv_txt, {}, (@cv_txt.classify + 's').to_sym, dimend_key)
    put_rsc_table(@rsc_table, gap, @cv_txt, dimend_key.to_s.to_snake_case)
    calc_gap_for_common(@rsc_table)

    @categories["参照元"] = set_select_box(@referral, 'r')

    @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
    @bedroom_partial = 'landing'
    @table_head = '参照元'

    render :layout => 'ganalytics', :action => 'show'
  end

  def direct
    # パラメータ個別設定
    @title = '直接入力/ブックマーク'
    @narrow_action = direct_user_path
    gon.div_page_tab = 'direct'

    @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
    @kitchen_partial = 'norender'
    @bedroom_partial = 'landing'

    render :layout => 'ganalytics', :action => 'show'
  end

  def search
    # パラメータ個別設定
    @title = '検索'
    @narrow_action = search_user_path
    @kitchen_partial = 'search'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'search'
    @search = Analytics::FetchKeywordForSearch.results(@ga_profile, @cond)
    @categories["検索ワード"] = set_select_box(@search, 's')

    @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
    @bedroom_partial = 'landing'

    render :layout => 'ganalytics', :action => 'show'
  end

  def index
    # @users = User.paginate(page: params[:page])
  end

  def show
    # パラメータ個別設定
    @title = 'ホーム'
    @narrow_action = user_path
    gon.narrow_action = user_path
    @kitchen_partial = 'norender'   # ページ毎の部分テンプレート
    @bedroom_partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'first'

    render json: {
      :homearr => @json,
      :page_fltr_wd => @page_fltr_wd,
      :page_fltr_dev => @page_fltr_dev,
      :page_fltr_usr => @page_fltr_usr,
      :page_fltr_kwd => @page_fltr_kwd
    } and return if request.xhr?

    render :layout => 'ganalytics', :file => '/app/views/users/first' and return
  end

  def all
    # パラメータ個別設定
    @title = '全体'
    @narrow_action = all_user_path
    @kitchen_partial = 'norender'   # ページ毎の部分テンプレート
    @bedroom_partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'all'

    render :layout => 'ganalytics', :action => 'show'
  end

  def new
    @user = User.new
  end

  def create
    params[:ga_password] = params[:password]
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      flash[:success] = "ようこそ！"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
  end

  def update
      if @user.update_attributes(user_params)
        flash[:success] = "Profile updated"
        redirect_to @user
      else
        render 'edit'
      end
  end

  def destroy
      User.find(params[:id]).destroy
      flash[:success] = "User destroyed."
      redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    # Before actions

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "ログインしてください"
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def chk_param

      @from = params[:from].presence || Date.today.prev_month
      @to = params[:to].presence || Date.today
      @from = set_date_format(@from) if params[:from].present?
      @to = set_date_format(@to) if params[:to].present?

      # ajaxリクエストの判定
      if request.xhr?

        @req_str = request.fullpath.to_s

        logger.info('req path is ' + @req_str)

        # キャッシュを取得する(キーワード数)
        cached_item = Rails.cache.read(@req_str)

        # キャッシュ読み書き(バブル用データ)
        if params[:analyze_type].present?

          analyze_type = params[:analyze_type].to_s

          uniq = create_cache_key(analyze_type)

          if params[:r_obj].present?

            puts 'set data for cache'

            # 格納用データオブジェクト
            s_txt = params[:r_obj].to_s

            # 結果をキャッシュへ格納してコントローラを抜ける
            # キャッシュの保持時間は1h
            Rails.cache.write(uniq, s_txt, expires_in: 1.hour, compress: true)

            # 分析完了メールを送信
            unless analyze_type == 'kobetsu'
              user = User.find(params[:id])
              UserMailer.send_message_for_complete_analyze(user, @from, @to).deliver if user
            end

            return
          else

            puts 'getting cached data'

            # データを読み込む
            cached_item = Rails.cache.read(uniq)
          end
        end

        # キャッシュ済のデータがあればキャッシュを返却してコントローラを抜ける
        if cached_item.present?
          puts 'cached_item is ' + cached_item
          @json = cached_item
          return
        else
          puts 'no cached_item'
        end
      end

      # パラメータ共通設定

      @user = User.find(params[:id])
      analyticsservice = AnalyticsService.new

      @session = analyticsservice.login(@user)                                     # アナリティクスAPI認証パラメータ１

      @ga_profile = analyticsservice.load_profile(@session, @user)                                     # アナリティクスAPI認証パラメータ２
      @ga_goal = analyticsservice.get_goal(@ga_profile)                                     # アナリティクスに設定されているCV
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

     @cv_num = (params[:cv_num].presence.to_i || 1)                                                     # CV種類
     if @cv_num == 0
        @cv_num = 1
     end

     gon.cv_num = @cv_num
      # 絞り込みキーワード
      @narrow_word = params[:narrow_select].presence
      if params[:narrow_select].present?
        gon.narrow_word = params[:narrow_select].dup
        @narrow_tag = params[:narrow_select][-1]
        @narrow_word.slice!(-1)
        set_narrow_word(@narrow_word, @cond, @narrow_tag) # 絞り込んだキーワード
      end
      # 絞り込みセレクトボックス項目を生成
      # ページ共通セレクトボックス(人気ページ)
      # @categories = {}
      # gb_cnd = Ganalytics::Garb::Cond.new(@cond)
      # @favorite = Analytics::FetchKeywordForPages.results(@ga_profile, gb_cnd.sort_favorite)
      # @head_favorite_table = head_favorite_table(@favorite, 5)
      # @favorite_rank = seikei_rank(@head_favorite_table)

      # @categories["人気ページ"] = set_select_box(@favorite, 'f')

      # 遷移元ページタブを保存
      gon.prev_page = params[:prev_page].presence

    end

    def create_common_table

      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')

      metrics_camel_case_datas = [] # アナリティクスAPIデータ取得用
      metrics_snake_case_datas = [] # データ構造構築用
      metrics_for_graph_merge = {} # jqplot用データ構築用
      get_metricses.each do |k, v|
        metrics_for_graph_merge[k.to_s.to_snake_case.to_sym] = {jp_caption: v}
        metrics_camel_case_datas.push(k)
        metrics_snake_case_datas.push(k.to_s.to_snake_case.to_sym)
      end
      # アナリティクスAPIに用意されていないもの
      get_metrics_not_ga.each do |k, v|
        metrics_for_graph_merge[k] = {jp_caption: v}
        metrics_snake_case_datas.push(k)
      end

      ### APIデータ取得部

      # リトライ時のメッセージを指定
      exception_cb = Proc.new do |retries|
        logger.info("API request retry: #{retries}")
      end

      ### APIデータ取得部

      # クラス名を一意にするため、乱数を算出
      rndm = SecureRandom.hex(4)

      # ソート条件追加用クラス
      gc = Ganalytics::Garb::Cond.new(@cond)

      # 指標値テーブルへCV代入用
      cls_name = 'CVForGraphSkeleton' + rndm.to_s
      # 4回までリトライできます
      retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        @cv_for_graph = Analytics.create_class(cls_name,
          [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
      end

      # 指標値算出用
      # 4回までリトライできます
      gap = ''
      retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        gap = fetch_analytics_data('Fetch', @ga_profile, @cond, @cv_txt, {}, metrics_camel_case_datas, :date)
      end

      # 人気ページ用
      fav_gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile, gc.sort_favorite_for_calc, @cv_txt)
      fav_for_skel = Analytics::FetchKeywordForPages.results(@ga_profile, gc.sort_favorite_for_skelton)

      # ランディングページ用
      land_gap = fetch_analytics_data('FetchKeywordForLanding', @ga_profile, gc.sort_landing_for_calc, @cv_txt)
      land_for_skel = Analytics::FetchKeywordForLanding.results(@ga_profile, gc.sort_landing_for_skelton)

      # 全てのセッション(GAP値等計算用)
      ga_result = Analytics.create_class('AllSession', [:sessions], []).results(@ga_profile, @cond).total_results
      tmp_all_session = ga_result.results[0].sessions.to_i if ga_result > 0
      all_session = guard_for_zero_division(tmp_all_session)

      ### データ計算部

      # グラフ表示用および指標値用テーブル
      @table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_for_graph(@table_for_graph, @from, @to, metrics_for_graph_merge)

      # CV値挿入
      put_cv_for_graph(@cv_for_graph, @table_for_graph, @cv_num)

      # GAP値をスケルトンへ挿入
      put_table_for_graph(gap, @table_for_graph, metrics_snake_case_datas)
      calc_gap_for_graph(@table_for_graph, metrics_snake_case_datas)

      # 指標値テーブルへ表示するデータを算出

      # @day_type = 'day_off'
      @desire_datas = generate_graph_data(@table_for_graph, metrics_snake_case_datas, @day_type)
      calc_desire_datas(desire_datas) # 目標値の算出

      graph_datas = generate_graph_data(@table_for_graph, metrics_snake_case_datas, @day_type)
      d_hsh = metrics_day_type_jp_caption(@day_type, metrics_for_graph_merge)
      @details_graph_data = concat_data_for_graph(graph_datas, d_hsh)


      # グラフ表示プログラムへ渡すデータを作成
      @data_for_graph_display = Hash.new{ |h,k| h[k] = {} }
      create_data_for_graph_display(@data_for_graph_display, @table_for_graph, @graphic_item)

      display_format = check_format_graph(@graphic_item)
      change_format(@table_for_graph, @graphic_item, display_format)

       gon.data_for_graph_display = @data_for_graph_display

      # 人気ページテーブル
      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

      cved_session = guard_for_zero_division(all_session - fav_gap['bad'].results.map { |t| t.sessions }.sum)
      not_cved_session = guard_for_zero_division(all_session - fav_gap['good'].results.map { |t| t.sessions }.sum)

      create_skeleton_favorite_table(fav_for_skel, @favorite_table)
      put_favorite_table_for_skelton(fav_gap, @favorite_table)

      calc_percent_for_favorite_table(cved_session, @favorite_table, :good)
      calc_percent_for_favorite_table(not_cved_session, @favorite_table, :bad)
      calc_gap_for_favorite(@favorite_table)

      # ランディングページテーブル
      @landing_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

      create_skeleton_landing_table(land_for_skel, @landing_table)
      put_landing_table_for_skelton(land_gap, @landing_table)
      calc_gap_for_favorite(@landing_table)

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

          logger.info('parameter keyword is ' + kwd)
          # キーワードがnokwdでない場合
          if params[:kwd].to_s != 'nokwd'

            kwd = params[:kwd].to_s
            p = kwd.slice!(0)

            # ページ項目の判定と、絞り込みキーワードの設定
            set_narrow_word(kwd, @cond, p)
          else
            kwd = 'nokwd'
          end

        elsif kwd.empty?

          # キャッシュ済のデータがあればコントローラを抜ける
          return if @json.present?

          # 絞り込みキーワードが指定されていない場合はキーワードを取得
          kwds = []
          case wd
          when 'search'
            search = Analytics::FetchKeywordForSearch.results(@ga_profile, @cond)
            aa = search.sort_by { |a|
              [ -(a.sessions.to_i),
                -(a.adsense_ads_clicks.to_i),
                -(a.adsense_ctr.to_f) ]
            }
            aa.each do |t|
                  kwds.push('s' + t.keyword)
                  if kwds.size >= 5 then break end
            end
          when 'direct'
            direct = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
            aa = direct.sort_by{ |a| [ -(a.sessions.to_f), -(a.bounce_rate.to_f) ] }
            aa.each do |t|
                  kwds.push('f' + t.page_title)
                  if kwds.size >= 5 then break end
            end
          when 'referral'
            dimend_key = :source
            referral = Analytics.create_class('FetchKeywordForRef',
                [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
            aa = referral.sort_by{ |a| -(a.cv.to_i ) }
            aa.each do |t|
              kwds.push('r' + t.source)
              if kwds.size >= 5 then break end
            end
          when 'social'
            dimend_key = :socialNetwork
            social = Analytics.create_class('FetchKeywordForSoc',
                [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
            aa = social.sort_by{ |a| -(a.cv.to_i ) }
            aa.each do |t|
              kwds.push( 'l' + t.social_network)
              if kwds.size >= 5 then break end
            end
          end

          # キーワード配列を格納
          @json = kwds.to_json

          # 結果をキャッシュへ格納
          Rails.cache.write(@req_str, @json, expires_in: 1.hour, compress: true)

          # コントローラを抜ける
          return
        end
        @page_fltr_kwd = kwd
        logger.info('setted keyword is ' + kwd)

        # キャッシュ済のデータがあればコントローラを抜ける
        return if @json.present?

        # ページ項目ごとにデータ集計
        p_hash = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

        # パラレル処理は考えていないが、一応残しておく（API制限がもしかしたら外れるかも。。）
        Parallel.map(page, :in_threads=>1) { |x, z|

          room = dev + '::' + usr + '::' + kwd           # デバイス::訪問者::キーワード

          # フィルタオプション追加（キーワードは追加済み）
          @cond[:filters].merge!(z)                            # ページ項目
          @cond[:filters].merge!(dev_opts[dev])       # デバイス
          @cond[:filters].merge!(usr_opts[usr])        # 訪問者

          # データ指標
          metrics_camel_case_datas = [] # アナリティクスAPIデータ取得用
          metrics_snake_case_datas = [] # データ構造構築用
          metrics_for_graph_merge = {} # jqplot用データ構築用
          get_metricses.each do |k, v|
            metrics_for_graph_merge[k.to_s.to_snake_case.to_sym] = {jp_caption: v}
            metrics_camel_case_datas.push(k)
            metrics_snake_case_datas.push(k.to_s.to_snake_case.to_sym)
          end
          # アナリティクスAPIに用意されていないもの
          get_metrics_not_ga.each do |k, v|
            metrics_for_graph_merge[k] = {jp_caption: v}
            metrics_snake_case_datas.push(k)
          end

          # リトライ時のメッセージを指定
          exception_cb = Proc.new do |retries|
            logger.info("API request retry: #{retries}")
          end

          ### APIデータ取得部

          # クラス名を一意にするため、乱数を算出
          rndm = SecureRandom.hex(4)

          # CV代入用
          cls_name = 'CVForGraphSkeleton' + rndm.to_s
          # 4回までリトライできます
          retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            @cv_for_graph = Analytics.create_class(cls_name,
              [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
          end

          # 指標値算出用
          # 4回までリトライできます
          gap = ''
          retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            gap = fetch_analytics_data('Fetch', @ga_profile,@cond, @cv_txt, {}, metrics_camel_case_datas, :date)
          end

          ### データ計算部

          # スケルトン作成
          @table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
          create_skeleton_for_graph(@table_for_graph, @from, @to, metrics_for_graph_merge)

          # CV代入用
          put_cv_for_graph(@cv_for_graph, @table_for_graph, @cv_num)

          # 指標値の算出
          put_table_for_graph(gap, @table_for_graph, metrics_snake_case_datas) # 項目の理想値、現実値をスケルトンへ代入

          calc_gap_for_graph(@table_for_graph, metrics_snake_case_datas) # スケルトンからGAP値を計算

          # バブルチャートに表示するデータを算出
         # @day_type = 'day_off'
          bubble_datas = generate_graph_data(@table_for_graph, metrics_snake_case_datas, @day_type)
          d_hsh = metrics_day_type_jp_caption(@day_type, metrics_for_graph_merge)
          home_graph_data = concat_data_for_graph(bubble_datas, d_hsh)

          # ページ項目へ追加
          p_hash[x][room] = home_graph_data
          logger.info("pages data set success!")

          # フィルタオプションのリセット
          logger.info("filters option reset start. now is #{@cond}")
          @cond[:filters] = {}
          logger.info("filters option reset end. now is #{@cond}")

        }

        # ループ終了。jqplot へデータ渡す
        if shori != 0
          @json = p_hash.to_json
        end
      end
    end
end
