class UsersController < ApplicationController
  require 'holiday_japan'
  require 'user_func'
  require 'create_table'
  require 'insert_table'
  require 'update_table'
  require 'parallel'
  include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
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

  def campaign
    # パラメータ個別設定
    @title = 'キャンペーン'
    @narrow_action = campaign_user_path
    @partial = 'rsc'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'campaign'

    # ページ個別設定
    # gap値の分処理が複雑
    dimend_key = :campaign
    @campaign = Analytics.create_class('FetchKeywordForCam',
        [ @cv_txt ], [ dimend_key ] ).results(@ga_profile, @cond)
    @rsc_table = create_skeleton_for_rsc(@campaign, dimend_key.to_s.to_snake_case)
    gap = fetch_analytics_data('FetchKeywordForSocial', @ga_profile, @cond, @cv_txt, {}, (@cv_txt.classify + 's').to_sym, dimend_key)
    put_rsc_table(@rsc_table, gap, @cv_txt, dimend_key.to_s.to_snake_case)
    calc_gap_for_common(@rsc_table)

    @categories["キャンペーン"] = set_select_box(@campaign, 'c')

    if @narrow_tag == 'c' then
      @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
      @partial = 'inpage'
    end

    render :layout => 'ganalytics', :action => 'show'
  end

  def social
    # パラメータ個別設定
    @title = 'ソーシャル'
    @narrow_action = social_user_path
    @partial = 'rsc'   # ページ毎の部分テンプレート
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

    if @narrow_tag == 'l' then
      @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
      @partial = 'inpage'
    end

    render :layout => 'ganalytics', :action => 'show'
  end

  def referral
    # パラメータ個別設定
    @title = 'その他ウェブサイト'
    @narrow_action = referral_user_path
    @partial = 'rsc'   # ページ毎の部分テンプレート
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

    if @narrow_tag == 'r' then
      @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
      @partial = 'inpage'
    end

    render :layout => 'ganalytics', :action => 'show'
  end

  def direct
    # パラメータ個別設定
    @title = '直接入力/ブックマーク'
    @narrow_action = direct_user_path
    gon.div_page_tab = 'direct'

    @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
    @partial = 'inpage'

    render :layout => 'ganalytics', :action => 'show'
  end

  def search
    # パラメータ個別設定
    @title = '検索'
    @narrow_action = search_user_path
    @partial = 'search'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'search'
    @search = Analytics::FetchKeywordForSearch.results(@ga_profile, @cond)
    @categories["検索ワード"] = set_select_box(@search, 's')

    # ページ個別設定
    if @narrow_tag == 's' then
      @in_table = Analytics::FetchKeywordForDetail.results(@ga_profile, @cond)
      @partial = 'inpage'
    end

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

    render json: {
      :homearr => @json,
      :page_fltr_wd => @page_fltr_wd } and return if request.xhr?
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
    beg
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
        redirect_to signin_url, notice: "Please sign in."
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
      # パラメータ共通設定

      @user = User.find(params[:id])
      @ga_profile = AnalyticsService.new.load_profile(@user)                                     # アナリティクスAPI認証パラメータ
      @from = params[:from].presence || Date.today.prev_month
      if params[:from].present? then @from = set_date_format(@from) end
      @to = params[:to].presence || Date.today
      if params[:to].present? then @to = set_date_format(@to) end
     @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
     set_action(params[:action], @cond)
      gon.radio_device = set_device_type( (params[:device].presence || "all"),@cond)                               # 使用端末
      gon.radio_visitor = set_visitor_type( (params[:visitor].presence || "all"),@cond)                                 # 来訪者
      #　グラフ表示項目
     @graphic_item  = (params[:graphic_item].presence || 'pageviews').to_sym
     gon.graphic_item = @graphic_item.to_s
     gon.format_string = check_format_graph(@graphic_item)
     @cv_num = (params[:cv_num].presence || 1)                                                     # CV種類
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
    end

    def create_common_table
       #　◆ページ共通のテーブルを生成

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
      all_sessions = @common_table[:sessions] # 総セッション数の取得（再訪問率計算用)

      # グラフテーブル
      @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      columns_for_graph = [@graphic_item] # セレクトボックスの値
      create_skeleton_for_graph(@gap_table_for_graph, @from, @to, columns_for_graph)
      @cv_for_graph = Analytics.create_class('CVForGraphSkeleton',
        [ (@cv_txt.classify + 's').to_sym ], [:date] ).results(@ga_profile,@cond) # CV値挿入
      put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)
      gap = fetch_analytics_data('GapDataForGraph', @ga_profile,@cond, @cv_txt, {}, @graphic_item)
      put_table_for_graph(gap, @gap_table_for_graph, [ @graphic_item ], all_sessions)
      calc_gap_for_graph(@gap_table_for_graph, columns_for_graph)
      # グラフ表示プログラムへ渡すハッシュを作成
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
      gap_for_repeat = fetch_analytics_data('CommonRepeatForGap', @ga_profile, @cond, @cv_txt,
        {:user_type.matches => 'Returning Visitor'} )
      put_common_for_gap(@gap_table, gap)
      put_common_for_gap(@gap_table, gap_for_repeat, all_sessions)
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

      # ページ項目
      page = {
        '全体' => {},
        '検索' => {:medium.matches => 'organic'},
        '直接入力ブックマーク' => {:medium.matches => '(none)'},
        'その他ウェブサイト' => {:medium.matches => 'referral'},
        'ソーシャル' => {:has_social_source_referral.matches => 'Yes'},
        'キャンペーン' => {:campaign.does_not_match => '(not set)'},
      }

      # フィルタリング項目
      options = {
        # 'pc' => { :device_category.matches => 'desktop' },
        # 'sphone' => {
        #   :device_category.matches => 'mobile',
        #   :mobile_input_selector.matches => 'touchscreen'
        # },
        # 'mobile' => {
        #  :device_category.matches => 'mobile',
        #   :mobile_input_selector.does_not_match => 'touchscreen'
        # },
        # 'new' => {:user_type.matches => 'New Visitor'},
        # 'repeat' => { :user_type.matches => 'Returning Visitor' },
        'all' => {}
      }

      # フラグで処理するか分ける
      shori = params[:shori].presence || 0
      if shori != 0

        # リクエストパラメータに応じてpageの項目を絞る
        wd = ' '
        if params[:act].present?
          # wd = params[:act]
          wd = params[:act].gsub(/\//, '')
        else
          wd = '全体'
        end
        @page_fltr_wd = wd
        page.select!{ |k,v| k == wd }

        # ページ項目ごとにデータ集計
        p_hash = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
        Parallel.map(page, :in_threads=>1) { |x, z|
          Parallel.map(options, :in_threads=>1) { |xy, zy|
          # フィルタオプション追加
            @cond[:filters].merge!(z)
            @cond[:filters].merge!(zy)

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

            # 再訪問率計算用のセッション総数
            @common = Analytics.create_class('Common',
              [
                :sessions,
                :pageviews
              ] ).results(@ga_profile,@cond)
            # 総セッション数の取得（再訪問率計算用)
            if @common.total_results == 0 then
              all_sessions = 1
            else
              all_sessions = @common[0][:sessions]
            end

            ## ◆相関算出

            # スケルトン作成
            @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
            create_skeleton_for_graph(@gap_table_for_graph, @from, @to, mets_sh)

            # CV代入
            @cv_for_graph = Analytics.create_class('CVForGraphSkeleton',
              [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
            put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)

            # GAP算出
            gap = fetch_analytics_data('Fetch', @ga_profile,@cond, @cv_txt, {}, mets_ca, :date)
            put_table_for_graph(gap, @gap_table_for_graph, mets_sa, all_sessions)
            gap_rep = fetch_analytics_data('GapDataForGraph', @ga_profile, @cond, @cv_txt, {}, :repeat_rate)
            put_table_for_graph(gap_rep, @gap_table_for_graph, [:repeat_rate], all_sessions)
            calc_gap_for_graph(@gap_table_for_graph, mets_sa)

            # 相関算出
            # 曜日別の計算をしているときは、ここでgap値も算出している
            corr = calc_corr(@gap_table_for_graph, mets_sa, @cvr_txt.to_sym)

            # スケルトン作成
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
            @favorite.each do |k, v|
              key = k.page_title + ";;" + k.page_path
              fmt_hsh[key] = k.pageviews
            end
            @ftbl = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
            create_skeleton_for_graph(@ftbl, @from, @to, fmt_hsh)
            # CV代入
            @cv_for_fav = Analytics.create_class('CVFav', f_mt, f_dm ).results(@ga_profile, @cond)
            put_cv_for_graph(@cv_for_fav, @ftbl, @cv_num, flg = 'fvt')
            # GAP算出
            fgap = fetch_analytics_data('PagesData', @ga_profile,@cond, @cv_txt, {}, f_mt, f_dm)
            put_favorite_table(fgap, @ftbl, flg = 'date')
            calc_gap_for_graph(@ftbl, fmt_hsh)
            # 相関算出
            fvt_corr = calc_corr(@ftbl, fmt_hsh, @cvr_txt.to_sym, flg = 'fvt')
            # top10 を抽出
            fvt_corr = substr_fav(fvt_corr, @rank_arr)
            # jqplotへデータを渡すため、キーを変更
            fvt_corr = Hash[ fvt_corr.map{ |k, v| ['fav_page' + '$$' + k.to_s, v] } ]

            # 各相関をマージ
            corr.merge!(fvt_corr)

            ## ◆GAP総数算出

            # 人気ページテーブル
            @s_ftbl = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
            create_skeleton_favorite_table(@favorite, @s_ftbl)
            gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile,@cond, @cv_txt)
            put_favorite_table(gap, @s_ftbl)
            calc_gap_for_favorite(@s_ftbl)
            fav_gap = substr_fav(@s_ftbl, @rank_arr)
            fav_gap = Hash[ fav_gap.map{ |k, v| ['fav_page' + '$$' + k.to_s, v] } ]

            # その他
            skel = create_skeleton_bubble(mets_sa)
            gap = fetch_analytics_data('Fetch', @ga_profile,@cond, @cv_txt, {}, mets_ca, [])
            put_common_for_gap(skel, gap)
            gap_rep = fetch_analytics_data('CommonRepeatForGap', @ga_profile, @cond, @cv_txt,
              {:user_type.matches => 'Returning Visitor'} )
            put_common_for_gap(skel, gap_rep, all_sessions) #再訪問率
            skel = calc_gap_for_common(skel)

            # 数値をパーセンテージへ再計算
            skel.merge!(fav_gap)

            gap_day = Hash.new{ |h, k| h[k] = {} }
            corr.each do |k, v|
              if k =~ /(day_off|day_on)/ then
                gap_day[k][:gap] = v[:gap]
              end
            end
            skel.merge!(gap_day)

            skel = calc_num_to_pct(skel)

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
            mets_sh.merge!(Hash[ @rank_arr.map{ |k| ['fav_page' + '$$' + k, '人気ページ' + ';;' + k] } ])
            mets_sh.delete('fav_page$$その他') # 人気ページのその他は不要

            homearr = concat(skel, corr, mets_sh)

            # ページ項目へ追加
            p_hash[x][xy] = homearr
            puts "pages data set success!"

            # フィルタオプションのリセット
            puts "filters option reset start. now is #{@cond}"
            @cond[:filters] = {}
            puts "filters option reset end. now is #{@cond}"
          }
        }
        # jqplot へデータ渡す
        if shori != 0
          # gon.watch.homearr = p_hash
          @json = p_hash.to_json
        end
      end
    end

end
