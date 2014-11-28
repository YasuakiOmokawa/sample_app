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

  # def campaign
  #   # パラメータ個別設定
  #   @title = 'キャンペーン'
  #   @narrow_action = campaign_user_path
  #   @partial = 'rsc'   # ページ毎の部分テンプレート
  #   gon.div_page_tab = 'campaign'

  #   # ページ個別設定
  #   # gap値の分処理が複雑
  #   dimend_key = :campaign
  #   @campaign = Analytics.create_class('FetchKeywordForCam',
  #       [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
  #   @rsc_table = create_skeleton_for_rsc(@campaign, dimend_key.to_s.to_snake_case)
  #   gap = fetch_analytics_data('FetchKeywordForSocial', @ga_profile, @cond, @cv_txt, {}, (@cv_txt.classify + 's').to_sym, dimend_key)
  #   put_rsc_table(@rsc_table, gap, @cv_txt, dimend_key.to_s.to_snake_case)
  #   calc_gap_for_common(@rsc_table)

  #   @categories["キャンペーン"] = set_select_box(@campaign, 'c')

  #   if @narrow_tag == 'c' then
  #     @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
  #     @partial = 'inpage'
  #   end
  #   @table_head = 'キャンペーン'

  #   render :layout => 'ganalytics', :action => 'show'
  # end

  def social
    # パラメータ個別設定
    @title = 'ソーシャル'
    @narrow_action = social_user_path
    @kitchen_partial = 'rsc'   # ページ毎の部分テンプレート
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
    @bedroom_partial = 'inpage'
    @table_head = 'ソーシャル'

    render :layout => 'ganalytics', :action => 'show'
  end

  def referral
    # パラメータ個別設定
    @title = 'その他ウェブサイト'
    @narrow_action = referral_user_path
    @kitchen_partial = 'rsc'   # ページ毎の部分テンプレート
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
    @bedroom_partial = 'inpage'
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
    @bedroom_partial = 'inpage'

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
    @bedroom_partial = 'inpage'

    # ページ個別設定
    # if @narrow_tag == 's' then
    # end

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
    @partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'first'

    # gon.display_dialog_onlogin_flg = User.find(params[:id]).limitanalyzeall <=> Time.now
    # gon.display_dialog_onlogin_flg = 1 if display_dialog_onlogin_flg.nil? || display_dialog_onlogin_flg == 1

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
    @partial = 'norender'   # ページ毎の部分テンプレート
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

      # 並列処理を選択しているか？
      # if params[:multi_id].present?
      #   multi_id = params[:multi_id].to_i
      #   @session = analyticsservice.login_multi(@user, multi_id)                                     # アナリティクスAPI認証パラメータ１
      # else
      @session = analyticsservice.login(@user)                                     # アナリティクスAPI認証パラメータ１
      # end

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
      @categories = {}
      @favorite = Analytics::FetchKeywordForPages.results(@ga_profile, @cond)
      @top_ten = top10(@favorite)
      @rank_arr = seikei_rank(@top_ten)

      @categories["人気ページ"] = set_select_box(@favorite, 'f')

      # 遷移元ページタブを保存
      gon.prev_page = params[:prev_page].presence

    end

    def create_common_table

      # ◆ページ共通のテーブルを生成

      # pv数 ~ 直帰率（ギャップなしデータ）
      @common_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
      create_skeleton(@common_table, @cv_txt, @cvr_txt)
      @common = Analytics.create_class('Common',
        [
          (@cv_txt.classify + 's').to_sym,
          @cvr_txt.classify.to_sym,
          :sessions,
          :pageviews,
          :bounceRate
        ] ).results(@ga_profile,@cond)
      put_common(@common_table, @common)

      all_sessions = @common_table[:sessions] # 共通ギャップ値テーブルの総セッション数の取得（再訪問率計算用)

      # グラフテーブル
      @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      columns_for_graph = [@graphic_item] # セレクトボックスから選んだグラフの種類
      create_skeleton_for_graph(@gap_table_for_graph, @from, @to, columns_for_graph)

      # CV値挿入
      @cv_for_graph = Analytics.create_class('CVForGraphSkeleton',
        [ (@cv_txt.classify + 's').to_sym ], [:date] ).results(@ga_profile,@cond)
      put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)

      # GAP値をスケルトンへ挿入
      gap = fetch_analytics_data('GapDataForGraph', @ga_profile, @cond, @cv_txt, {})
      put_table_for_graph(gap, @gap_table_for_graph, [ @graphic_item ])
      calc_gap_for_graph(@gap_table_for_graph, columns_for_graph)

      # グラフ表示プログラムへ渡すCVデータのハッシュを作成
      @hash_for_graph = Hash.new{ |h,k| h[k] = {} }
      create_array_for_graph(@hash_for_graph, @gap_table_for_graph, @graphic_item)
      gon.hash_for_graph = @hash_for_graph

      # 曜日別テーブル
      @value_table_by_days = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_table_by_days(@value_table_by_days, @gap_table_for_graph, @graphic_item)

      # グラフ値フォーマット設定(グラフテーブル生成の最後にやんないと表示が崩れる)
      format = check_format_graph(@graphic_item)
      change_format(@gap_table_for_graph, @graphic_item, format)

      # 平均PV数 ~ 再訪問率テーブル（ギャップありデータ）
      @gap_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_gap_table(@gap_table)
      gap = fetch_analytics_data('CommonForGap', @ga_profile, @cond, @cv_txt)

      put_common_for_gap(@gap_table, gap, all_sessions)
      calc_gap_for_common(@gap_table)

      # 時間のフォーマットを変更
      [:good, :bad, :gap].each do |t|

        # ギャップテーブル
        @gap_table[:avg_session_duration][t] = chg_time(@gap_table[:avg_session_duration][t])

        # 曜日別テーブル
        if @graphic_item == :avg_session_duration
          [:day_on, :day_off].each do |s|
            @value_table_by_days[s][t] = chg_time(@value_table_by_days[s][t])
          end
        end
      end

      # 人気ページテーブル
      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_favorite_table(@favorite, @favorite_table)
      gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile,@cond, @cv_txt)
      put_favorite_table(gap, @favorite_table)
      calc_gap_for_favorite(@favorite_table)
      # top10 を抽出
      @favorite_table = substr_fav(@favorite_table, @rank_arr)
    end

    def create_home

      #　◆ページ先頭のバブルチャートを生成

      @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
      cv = @cv_txt

      # ページ項目
      page = {
        '全体' => {},
        '検索' => {:medium.matches => 'organic'},
        '直接入力ブックマーク' => {:medium.matches => '(none)'},
        'その他ウェブサイト' => {:medium.matches => 'referral'},
        'ソーシャル' => {:has_social_source_referral.matches => 'Yes'},
        'キャンペーン' => {:campaign.does_not_match => '(not set)'},
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
          wd = params[:act].gsub(/\//, '')
        else
          # 初期値は全体
          wd = '全体'
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
          when '検索'
            search = Analytics::FetchKeywordForSearch.results(@ga_profile, @cond)
            search.sort_by{ |a|
              [ -(a.sessions.to_i),
                -(a.adsense_ads_clicks.to_i),
                -(a.adsense_ctr.to_f) ]
            }.each do |t|
                  kwds.push('s' + t.keyword)
                  if kwds.size >= 5 then break end
            end
          when '直接入力ブックマーク'
            direct = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)

            direct.sort_by{ |a| [ -(a.sessions.to_f), -(a.bounce_rate.to_f) ] }.each do |t|
                  kwds.push('f' + t.page_title)
                  if kwds.size >= 5 then break end
            end
          when 'その他ウェブサイト'
            dimend_key = :source
            referral = Analytics.create_class('FetchKeywordForRef',
                [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)

            referral.sort_by{ |a| -(a.cv.to_i ) }.each do |t|
              kwds.push('r' + t.source)
              if kwds.size >= 5 then break end
            end
          when 'ソーシャル'
            dimend_key = :socialNetwork
            social = Analytics.create_class('FetchKeywordForSoc',
                [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)

            social.sort_by{ |a| -(a.cv.to_i ) }.each do |t|
              kwds.push( 'l' + t.social_network)
              if kwds.size >= 5 then break end
            end
          when 'キャンペーン'
            dimend_key = :campaign
            campaign = Analytics.create_class('FetchKeywordForCam',
                [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)

            campaign.sort_by{ |a| -(a.cv.to_i ) }.each do |t|
              kwds.push( 'c' + t.campaign)
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

          # データ項目
          mets = {
            @cvr_txt.classify.to_sym => 'CVR',
            :pageviews => 'PV数',
            :pageviewsPerSession => '平均PV数',
            :sessions => '訪問回数',
            :avgSessionDuration => '平均滞在時間',
            :bounceRate => '直帰率',
            :percentNewSessions => '新規訪問率',
          }
          mets_ca = [] # アナリティクスAPIデータ取得用
          mets_sa = [] # データ構造構築用
          mets_sh = {} # jqplot用データ構築用
          mets.each do |k, v|
            mets_sh[k.to_s.to_snake_case.to_sym] = v
            mets_ca.push(k)
            mets_sa.push(k.to_s.to_snake_case.to_sym)
          end
          # アナリティクスAPIに用意されていないもの
          {
            :repeat_rate => '再訪問率',
          }.each do |k, v|
            mets_sh[k] = v
            mets_sa.push(k)
          end

          # 人気ページ用スケルトン作成
          f_mt = [
              (@cv_txt.classify + 's').to_sym,
              :pageviews
          ]
          f_dm = [
              :date,
              :pageTitle,
              :pagePath
          ]
          fmt_hsh = {}
          @top_ten.each do |k, v|
            key = v[0] + ";;" + v[1]
            fmt_hsh[key] = v[2]
          end

          # リトライ時のメッセージを指定
          exception_cb = Proc.new do |retries|
            puts "API request retry: #{retries}"
          end

          ### APIデータ取得部

          ## ◆相関算出

          # クラス名を一意にするため、乱数を算出
          rndm = SecureRandom.hex(4)

          # CV代入用
          cls_name = 'CVForGraphSkeleton' + rndm.to_s
          # 4回までリトライできます
          retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            @cv_for_graph = Analytics.create_class(cls_name,
              [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
          end

          # 相関のGAP値算出用
          # 4回までリトライできます
          gap = ''
          retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            gap = fetch_analytics_data('Fetch', @ga_profile,@cond, @cv_txt, {}, mets_ca, :date)
          end

          # # 人気ページ相関のCV代入用
          # cls_name = 'CVFav' + rndm.to_s
          # # 4回までリトライできます
          # retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
          #   @cv_for_fav = Analytics.create_class(cls_name, f_mt, f_dm ).results(@ga_profile, @cond)
          # end

          # # 人気ページ相関のGAP算出用
          # # 4回までリトライできます
          # fgap = ''
          # retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
          #   fgap = fetch_analytics_data('PagesData', @ga_profile,@cond, @cv_txt, {}, f_mt, f_dm)
          # end

          ## ◆GAP算出

          # 人気ページテーブル用
          # 4回までリトライできます
          # pg_gap = ''
          # retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
          #   pg_gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile,@cond, @cv_txt)
          # end

          # その他テーブル用
          # 4回までリトライできます
          sonota_gap = ''
          retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
            sonota_gap = fetch_analytics_data('FetchSonota', @ga_profile,@cond, @cv_txt, {}, mets_ca, [])
          end


          ### データ計算部

          ## ◆相関算出

          # スケルトン作成
          @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
          create_skeleton_for_graph(@gap_table_for_graph, @from, @to, mets_sh)

          # CV代入
          put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)

          # 相関のGAPを算出
          put_table_for_graph(gap, @gap_table_for_graph, mets_sa) # 項目の理想値、現実値をスケルトンへ代入

          calc_gap_for_graph(@gap_table_for_graph, mets_sa) # スケルトンからGAP値を計算

          # 相関算出
          # 曜日別の計算をしているときは、ここでgap値も算出している

          corr = calc_corr(@gap_table_for_graph, mets_sa, @cvr_txt.to_sym)

          # 人気ページ
          # @ftbl = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
          # create_skeleton_for_graph(@ftbl, @from, @to, fmt_hsh)

          # # 人気ページCV代入
          # put_cv_for_graph(@cv_for_fav, @ftbl, @cv_num, flg = 'fvt')

          # # 人気ページGAP算出
          # put_favorite_table(fgap, @ftbl, flg = 'date')
          # calc_gap_for_graph(@ftbl, fmt_hsh)

          # # 相関算出
          # fvt_corr = calc_corr(@ftbl, fmt_hsh, @cvr_txt.to_sym, flg = 'fvt')

          # # top10 を抽出
          # fvt_corr = substr_fav(fvt_corr, @rank_arr)

          # # jqplotへデータを渡すため、キーを変更
          # fvt_corr = Hash[ fvt_corr.map{ |k, v| ['fav_page' + '$$' + k.to_s, v] } ]

          # # 各相関をマージ
          # corr.merge!(fvt_corr)

          # 曜日別GAPを抜き出す
          gap_day = pickup_gap_per_day(corr)


          ## ◆GAP算出

          # 人気ページテーブル
          # @s_ftbl = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
          # create_skeleton_favorite_table(@favorite, @s_ftbl)
          # put_favorite_table(pg_gap, @s_ftbl)
          # calc_gap_for_favorite(@s_ftbl)
          # fav_gap = substr_fav(@s_ftbl, @rank_arr)
          # fav_gap = Hash[ fav_gap.map{ |k, v| ['fav_page' + '$$' + k.to_s, v] } ]

          # その他テーブル
          skel = create_skeleton_bubble(mets_sa)
          put_common_for_gap(skel, sonota_gap)
          skel = calc_gap_for_common(skel)

          # 日別、人気ページ別gapをマージ
          # skel.merge!(fav_gap)
          skel.merge!(gap_day)

          # グラフ表示用に、gap値を絶対値へ変換
          change_gap_to_abs(skel)

          # pageviews, sessions, bounce_rate のgap値を項目値へ変更（グラフ表示の為）
          change_gap_to_komoku(skel)

          # 数値をパーセンテージへ再計算
          re_calced_skel = calc_num_to_pct(skel)

          # jqplot用データ構築
          # mets_sh の キーが、実際にグラフに渡される値
          # mets_sh の値は、グラフの表示項目を示す
          mets_sh.delete(@cvr_txt.to_sym) #CVRは不要
          hsh = {}
          mets_sh.each do |k, v|
            {:day_off => '土日祝', :day_on => '平日'}.each do |c,d|
              key = k.to_s + ' ' + c.to_s
              val = v.to_s + ';;' + d.to_s
              hsh[key] = val
            end
          end
          mets_sh.merge!(hsh)
          # mets_sh.merge!(Hash[ @rank_arr.map{ |k| ['fav_page' + '$$' + k, '人気ページ' + ';;' + k] } ])
          # mets_sh.delete('fav_page$$その他') # 人気ページのその他は不要

          homearr = concat(re_calced_skel, corr, mets_sh)

          # ページ項目へ追加
          p_hash[x][room] = homearr
          logger.info("pages data set success!")

          # フィルタオプションのリセット
          logger.info("filters option reset start. now is #{@cond}")
          @cond[:filters] = {}
          logger.info("filters option reset end. now is #{@cond}")

        }

        # ループ終了。jqplot へデータ渡す
        if shori != 0
          @json = p_hash.to_json

          # 結果をキャッシュへ格納
          # Rails.cache.write(@req_str, @json, expires_in: 1.hour, compress: true)
        end
      end
    end
end
