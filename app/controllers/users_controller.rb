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

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :show, :all, :search, :direct, :referral, :social, :campaign]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy
  before_action :create_common_table, only: [:all, :search, :direct, :referral, :social, :campaign]
  before_action :create_home, only: [:show]
  prepend_before_action :chk_param, only: [:show, :all, :search, :direct, :referral, :social, :campaign]

  def social
    # パラメータ個別設定
    @title = 'ソーシャル'
    @narrow_action = social_user_path
    gon.div_page_tab = 'social'

    special = :socialNetwork
    # データ取得部
    soc_source = Analytics.create_class('Soc',
      [ :sessions], [special] ).results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res)

    soc_gap = fetch_analytics_data('Fetch',
      @ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res,
      @cv_txt, {}, [:sessions, (@cv_txt.classify + 's').to_sym], [:date, special])

    # 計算部
    soc_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    tmp_soc_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_for_soc(soc_source, tmp_soc_table, @from, @to, [:sessions])

    soc_source.each do |k|
      src = k.send(special.to_s.to_snake_case).to_sym
      str_src = k.send(special.to_s.to_snake_case).to_s
      type_komoku = komoku_day_type(:sessions, @day_type)
      put_cv_data_to_table_for_graph(@cv_for_graph, tmp_soc_table[src], @cv_num)
      put_table_for_special(soc_gap, tmp_soc_table[src], [:sessions], special.to_s.to_snake_case, str_src)
      soc_table[src] = calc_desire_datas(
        generate_graph_data(tmp_soc_table[src], [:sessions], @day_type))[type_komoku]
    end

    @in_table = head_special(soc_table, 3)     # 相関係数の高い順にソート

    ar = []
    cnt = 1
    @in_table.each do |k, v|
      cap = '参照元' + chk_num_charactor(cnt) + '　セッション'
      ar.push( [cap, k.to_s + 'l'] )
      cnt += 1
    end
    @categories = ar
    @details_partial = 'details'

    render :layout => 'ganalytics', :action => 'show'
  end

  def referral
    # パラメータ個別設定
    @title = 'その他ウェブサイト'
    @narrow_action = referral_user_path
    gon.div_page_tab = 'referral'

    special = :source
    # データ取得部
    ref_source = Analytics.create_class('Ref',
      [ :sessions], [special] ).results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res)

    ref_gap = fetch_analytics_data('Fetch',
      @ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res,
      @cv_txt, {}, [:sessions, (@cv_txt.classify + 's').to_sym], [:date, special])

    # 計算部
    ref_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    tmp_ref_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_for_ref(ref_source, tmp_ref_table, @from, @to, [:sessions])

    ref_source.each do |k|
      src = k.send(special).to_sym
      str_src = k.send(special).to_s
      type_komoku = komoku_day_type(:sessions, @day_type)
      put_cv_data_to_table_for_graph(@cv_for_graph, tmp_ref_table[src], @cv_num)
      put_table_for_special(ref_gap, tmp_ref_table[src], [:sessions], special, str_src)
      ref_table[src] = calc_desire_datas(
        generate_graph_data(tmp_ref_table[src], [:sessions], @day_type))[type_komoku]
    end

    @in_table = head_special(ref_table, 3)     # 相関係数の高い順にソート

    ar = []
    cnt = 1
    @in_table.each do |k, v|
      cap = '参照元' + chk_num_charactor(cnt) + '　セッション'
      ar.push( [cap, k.to_s + 'r'] )
      cnt += 1
    end
    @categories = ar
    @details_partial = 'details'

    render :layout => 'ganalytics', :action => 'show'
  end

  def direct
    # パラメータ個別設定
    @title = '直接入力/ブックマーク'
    @narrow_action = direct_user_path
    gon.div_page_tab = 'direct'

    @details_partial = 'norender'

    render :layout => 'ganalytics', :action => 'show'
  end

  def search
    # パラメータ個別設定
    @title = '検索'
    @narrow_action = search_user_path
    gon.div_page_tab = 'search'
    @details_partial = 'norender'

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
    @details_partial = 'norender'   # ページ毎の部分テンプレート
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

        logger.info('リクエストパラメータのフルパスは以下です。')
        logger.info(@req_str)

        cached_item = Rails.cache.read(@req_str)
        logger.info('キャッシュされたキーワードデータが読み込まれました。') unless cached_item.nil?

        # キャッシュ読み書き(バブル用データ)
        if params[:analyze_type].present?

          memcache_graph_key = create_cache_key(params[:analyze_type].to_s)

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
          # logger.info( cached_item)
          @json = cached_item
          return
        else
          logger.info( 'リクエストされたキーに紐づいているキャッシュデータはありません。')
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
      # 絞り込みセレクトボックス
      @categories = []

      # 日付タイプを設定
      @day_type = params[:day_type].presence || 'all_day'
      gon.radio_day = @day_type
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

      # クラス名を一意にするため、乱数を算出
      rndm = SecureRandom.hex(4)

      # 指標値テーブルへCV代入用
      cls_name = 'CVForGraphSkeleton' + rndm.to_s
      # 4回までリトライできます
      Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        @cv_for_graph = Analytics.create_class(cls_name,
          [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
      end

      # 指標値算出用
      # 4回までリトライできます
      gap = ''
      Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
        gap = fetch_analytics_data('Fetch', @ga_profile, @cond, @cv_txt, {}, metrics_camel_case_datas, :date)
      end

      # 人気ページ用
      fav_gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(100).sort_desc!(:sessions).res, @cv_txt)
      fav_for_skel = Analytics::FetchKeywordForPages.results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).res)

      # ランディングページ用
      land_for_skel = Analytics::FetchKeywordForLanding.results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:bounceRate).cved!.res)

      # 全てのセッション(人気ページGAP値等計算用)
      ga_result = Analytics.create_class('AllSession', [:sessions], []).results(@ga_profile, @cond)
      tmp_all_session = ga_result.results[0].sessions.to_i if ga_result.total_results > 0
      all_session = guard_for_zero_division(tmp_all_session)

      ### データ計算部

       # グラフデータテーブルへ表示する指標値
      @desire_caption =  metrics_for_graph_merge[@graphic_item][:jp_caption]

      # グラフ表示用および指標値用テーブル
      @table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_for_graph(@table_for_graph, @from, @to, metrics_for_graph_merge)

      # CV値挿入
      put_cv_data_to_table_for_graph(@cv_for_graph, @table_for_graph, @cv_num)

      # GAP値をスケルトンへ挿入
      put_metrics_data_to_table_for_graph(gap, @table_for_graph, metrics_snake_case_datas)
      calc_gap_for_graph(@table_for_graph, metrics_snake_case_datas)

      # 指標値テーブルへ表示するデータを算出
      desire_datas = generate_graph_data(@table_for_graph, metrics_snake_case_datas, @day_type)
      calc_desire_datas(desire_datas) # 目標値の算出

      # 日本語データを追加
      d_hsh = metrics_day_type_jp_caption(@day_type, metrics_for_graph_merge)
      @details_desire_datas = concat_data_for_graph(desire_datas, d_hsh)

      # グラフ表示プログラムへ渡すデータを作成
      @data_for_graph_display = Hash.new{ |h,k| h[k] = {} }
      ym = group_by_year_and_month(@table_for_graph)

      create_data_for_graph_display(@data_for_graph_display, @table_for_graph, @graphic_item)
      if chk_monthly?(ym) == true
        @data_for_graph_display = create_monthly_summary_data_for_graph_display(@data_for_graph_display, ym, @graphic_item)
      end
      gon.data_for_graph_display = @data_for_graph_display

      # グラフテーブルへ渡すデータを作成
      @data_for_graph_table = Hash.new{ |h,k| h[k] = {} }
      create_data_for_graph_display(@data_for_graph_table, @table_for_graph, @graphic_item)

      ## フォーマット変更

        # 目標値データへ
        @details_desire_datas.each do |k, v|
          change_format_for_desire(@details_desire_datas[k], check_format_graph(k).to_s, v)
        end

        # グラフテーブルへ
        @data_for_graph_table.each do |k, v|
          change_format_for_graph_table(@data_for_graph_table[k], check_format_graph(@graphic_item), v[0] )
        end

      # 人気ページテーブル
      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      cved_session = guard_for_zero_division(all_session - fav_gap['bad'].results.map { |t| t.sessions.to_i }.sum)
      not_cved_session = guard_for_zero_division(all_session - fav_gap['good'].results.map { |t| t.sessions.to_i }.sum)

      create_skeleton_favorite_table(fav_for_skel, @favorite_table)
      put_favorite_table_for_skelton(fav_gap, @favorite_table)

      calc_percent_for_favorite_table(cved_session, @favorite_table, :good)
      calc_percent_for_favorite_table(not_cved_session, @favorite_table, :bad)
      calc_gap_for_favorite(@favorite_table)

      # ランディングページテーブル
      land_for_skel = Analytics::FetchKeywordForLanding.results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:bounceRate).res)
      @landing_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      @landing_table = put_landing_table(land_for_skel, @landing_table)

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
            ref_source = Analytics.create_class('Ref',
              [ :sessions], [special] ).results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(3).sort_desc!(:sessions).res)
            ref_source.each do |t|
              kwds.push('r' + t.source)
            end
          when 'social'
            special = :socialNetwork
            # データ取得部
            soc_source = Analytics.create_class('Soc',
              [ :sessions], [special] ).results(@ga_profile, Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(3).sort_desc!(:sessions).res)
            soc_source.each do |t|
              kwds.push( 'l' + t.social_network)
            end
          end
          @cond[:filters] = {}

          # キーワード配列を格納
          @json = kwds.to_json

          # 結果をキャッシュへ格納
          logger.info( "絞り込み条件を取得しました。キャッシュへ登録します。")
          Rails.cache.write(@req_str, @json, expires_in: 1.hour, compress: true)

          # コントローラを抜ける
          return
        end

        @page_fltr_kwd = kwd
        logger.info('設定されたキーワードは ' + kwd)

        # キャッシュ済のデータがあればコントローラを抜ける
        return if @json.present?

        # ページ項目ごとにデータ集計
        p_hash = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言

        # パラレル処理は考えていないが、一応残しておく（API制限がもしかしたら外れるかも。。）
        analyze_day_types = []
        Parallel.map(page, :in_threads=>1) { |x, z|

          room = dev + '::' + usr + '::' + kwd           # デバイス::訪問者::キーワード

          # フィルタオプション追加（キーワードは追加済み）
          @cond[:filters].merge!(z)                            # ページ項目
          @cond[:filters].merge!(dev_opts[dev])       # デバイス
          @cond[:filters].merge!(usr_opts[usr])        # 訪問者

          # データ指標
          metrics = Metrics.new()
          metrics_camel_case_datas = metrics.garb_parameter
          metrics_snake_case_datas = metrics.garb_result
          metrics_for_graph_merge = metrics.jp_caption

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
          Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            @cv_for_graph = Analytics.create_class(cls_name,
              [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
          end

          # 指標値算出用
          # 4回までリトライできます
          gap = ''
          Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            gap = fetch_analytics_data('Fetch', @ga_profile,@cond, @cv_txt, {}, metrics_camel_case_datas, :date)
          end

          ### データ計算部

          @table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
          create_skeleton_for_graph(@table_for_graph, @from, @to, metrics_for_graph_merge)
          put_cv_data_to_table_for_graph(@cv_for_graph, @table_for_graph, @cv_num)
          put_metrics_data_to_table_for_graph(gap, @table_for_graph, metrics_snake_case_datas)

          analyze_day_types = get_analyzable_day_types(@table_for_graph)
          unless analyze_day_types.blank?

            calc_gap_for_graph(@table_for_graph, metrics_snake_case_datas) # スケルトンからGAP値を計算

            # バブルチャートに表示するデータを算出
            analyze_day_types.each do |day_type|
              bubble_datas = generate_graph_data(@table_for_graph, metrics_snake_case_datas, day_type)
              d_hsh = metrics_day_type_jp_caption(day_type, metrics_for_graph_merge)
              home_graph_data = concat_data_for_graph(bubble_datas, d_hsh)

              # ページ項目へ追加
              day_room = room +  '::' + day_type
              p_hash[x][day_room] = home_graph_data
              logger.info("pages data set success!")
            end

            # フィルタオプションのリセット
            logger.info("filters option reset start. now is #{@cond}")
            @cond[:filters] = {}
            logger.info("filters option reset end. now is #{@cond}")

          end
        }
        return if analyze_day_types.blank?

        # ループ終了。jqplot へデータ渡す
        if shori != 0
          @json = p_hash.to_json
        end
      end
    end
end
