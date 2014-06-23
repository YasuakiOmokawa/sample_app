class UsersController < ApplicationController
  require 'holiday_japan'
  require 'user_func'
  require 'create_table'
  require 'insert_table'
  require 'update_table'
  include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy
  before_action :chk_param, :create_common_table, only: [:show, :search, :direct, :referral, :social, :campaign, :last]


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
    @cond[:filters].merge!( {
      :campaign.does_not_match => '(not set)'
      })

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
    @cond[:filters].merge!( {
      :has_social_source_referral.matches => 'Yes'
      })

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
    @cond[:filters].merge!( {
      :medium.matches => 'referral'
      })

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
    @cond[:filters].merge!( {
      :medium.matches => '(none)'
      })

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
    @cond[:filters].merge!( {
      :medium.matches => 'organic'
      })
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
    @users = User.paginate(page: params[:page])
  end

  def show
    # パラメータ個別設定
    @title = '全体'
    @narrow_action = user_path
    @partial = 'norender'   # ページ毎の部分テンプレート
    gon.div_page_tab = 'show'

    render :layout => 'ganalytics'
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Sample App!"
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
      @from = params[:from].presence || Date.today
      if params[:from].present? then @from = set_date_format(@from) end
      @to = params[:to].presence || Date.today.next_month
      if params[:to].present? then @to = set_date_format(@to) end
     @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
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
      all_sessions = @common_table[:sessions] # 総セッション数の取得（リピート率計算用)

      # グラフテーブル
      @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      columns_for_graph = [@graphic_item] # セレクトボックスの値
      create_skeleton_for_graph(@gap_table_for_graph, @from, @to, columns_for_graph)
      @cv_for_graph = Analytics.create_class('CVForGraphSkeleton',
        [ (@cv_txt.classify + 's').to_sym ], [:date] ).results(@ga_profile,@cond) # CV値挿入
      put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)
      gap = fetch_analytics_data('GapDataForGraph', @ga_profile,@cond, @cv_txt, {}, @graphic_item)
      put_table_for_graph(gap, @gap_table_for_graph, @graphic_item, all_sessions)
      calc_gap_for_graph(@gap_table_for_graph, columns_for_graph)
      # グラフ表示プログラムへ渡すハッシュを作成
      @hash_for_graph = Hash.new{ |h,k| h[k] = {} }
      create_array_for_graph(@hash_for_graph, @gap_table_for_graph, @graphic_item)
      gon.hash_for_graph = @hash_for_graph

      # 曜日別値テーブル
      @value_table_by_days = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_table_by_days(@value_table_by_days, @gap_table_for_graph, @graphic_item)

      # グラフ値フォーマット設定(グラフテーブル生成の最後にやんないと表示が崩れる)
      format = check_format_graph(@graphic_item)
      change_format(@gap_table_for_graph, @graphic_item, format)

      # 平均PV数 ~ リピート率テーブル（ギャップありデータ）
      @gap_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_gap_table(@gap_table)
      gap = fetch_analytics_data('CommonForGap', @ga_profile,@cond, @cv_txt)
      gap_for_repeat = fetch_analytics_data('CommonRepeatForGap', @ga_profile,@cond, @cv_txt,
        {:user_type.matches => 'Returning Visitor'} )
      put_common_for_gap(@gap_table, gap)
      put_common_for_gap(@gap_table, gap_for_repeat, all_sessions)
      calc_gap_for_common(@gap_table)

      # 人気ページテーブル
      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      create_skeleton_favorite_table(@favorite, @favorite_table)
      gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile,@cond, @cv_txt)
      put_favorite_table(gap, @favorite_table)
      calc_gap_for_favorite(@favorite_table)
    end
end
