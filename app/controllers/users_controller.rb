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

  def search
    # ページ固有設定
    @title = '検索'
    @narrow_action = search_user_path
    # 絞り込み条件が「人気ページ」以外だった場合、部分テンプレートを変更する
    @narrow_word = params[:narrow_select]
    @render_action = 'search'

    # ページ特有
    @select_word_for_board= Analytics::FetchKeywordForSearch.results(ga_profile, cond)
    select_word_arr = []
    @select_word_for_board.each do |w|
      select_word_arr.push([ w.keyword, w.keyword ])
    end
    @categories["検索ワード"] = select_word_arr

  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    # ------- パラメータ設定セクション start ------- #
    @title = '全体'
    @user = User.find(params[:id])
    @narrow_action = user_path
    @from = params[:from].presence || Date.today
    if params[:from].present? then @from = set_date_format(@from) end
    @to = params[:to].presence || Date.today.next_month
    if params[:to].present? then @to = set_date_format(@to) end
    ga_profile = AnalyticsService.new.load_profile(@user)                                     # アナリティクスAPI認証パラメータ
    cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
    set_device_type( (params[:device].presence || "all"), cond)                               # 使用端末
    set_visitor_type( (params[:visitor].presence || "all"), cond)                                 # 来訪者
    # グラフ表示項目
    @graphic_item  = (params[:graphic_item].presence || 'pageviews').to_sym
    gon.format_string = check_format_graph(@graphic_item)
    @cv_num = (params[:cv_num].presence || 1).to_sym                                       # CV種類
    @render_action = 'norender'                                                                                # ページ毎の部分テンプレート
    # 絞り込みキーワード
    @narrow_word = params[:narrow_select].presence
    if params[:narrow_select].present?
      set_narrow_word(@narrow_word, cond)
    end
    # 絞り込みセレクトボックス項目を生成
    @categories = {}
    # ページ共通セレクトボックス(人気ページ)
    @favorites = []
    @favorite = Analytics::FetchKeywordForPages.results(ga_profile, cond)
    @categories["人気ページ"] = set_select_box(@favorites, @favorite)
    # ------- パラメータ設定セクション end ------- #

    # ------- テーブルデータ生成セクション start ------- #

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
      ] ).results(ga_profile, cond)
    put_common(@common_table, @common)
    all_sessions = @common_table[:sessions] # 総セッション数の取得（リピート率計算用)

    # グラフテーブル
    @gap_table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    columns_for_graph = [@graphic_item] # セレクトボックスの値
    create_skeleton_for_graph(@gap_table_for_graph, @from, @to, columns_for_graph)
    @cv_for_graph = Analytics.create_class('CVForGraphSkeleton',
      [ (@cv_txt.classify + 's').to_sym ], [:date] ).results(ga_profile, cond) # CV値挿入
    put_cv_for_graph(@cv_for_graph, @gap_table_for_graph, @cv_num)
    gap = fetch_analytics_data('GapDataForGraph', ga_profile, cond, @cv_txt, {}, @graphic_item)
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
    gap = fetch_analytics_data('CommonForGap', ga_profile, cond, @cv_txt)
    gap_for_repeat = fetch_analytics_data('CommonRepeatForGap', ga_profile, cond, @cv_txt,
      {:user_type.matches => 'Returning Visitor'} )
    put_common_for_gap(@gap_table, gap)
    put_common_for_gap(@gap_table, gap_for_repeat, all_sessions)
    calc_gap_for_common(@gap_table)

    # 人気ページテーブル
    @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_favorite_table(@favorite, @favorite_table)
    gap = fetch_analytics_data('FetchKeywordForPages', ga_profile, cond, @cv_txt)
    put_favorite_table(gap, @favorite_table)
    calc_gap_for_favorite(@favorite_table)

    #　◆ページ固有のテーブルを生成


    # ------- テーブルデータ生成セクション end ------- #

    @cond = cond.dup

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

end
