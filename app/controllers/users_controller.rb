class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def search
    @title = '検索'
    @user = User.find(params[:id])
    @narrow_action = search_user_path
    # 絞り込み条件が「人気ページ」以外だった場合、部分テンプレートを変更する
    @narrow_word = params[:narrow_select]
    @render_action = 'search'
    analytics = AnalyticsService.new
    # アナリティクス認証
    ga_profile = analytics.load_profile(@user)
    # アナリティクス条件のハッシュ
    cond = {
        :start_date => Time.parse("2012-12-05"),
        :end_date   => Time.parse('2013-01-05'),
        :filters    => { :medium.matches => 'organic' }
    }

    # ページ共通の項目を生成
    @not_gap_data_for_kitchen = AnalyticsServiceClass::NotGapDataForKitchen.results(ga_profile, cond)

    # 絞り込みセレクトボックス項目を生成
    @categories = {}
    # ページ特有
    @select_word_for_board= AnalyticsServiceClass::FetchKeywordForSearch.results(ga_profile, cond)
    @select_word_arr = []
    @select_word_for_board.each do |w|
      @select_word_arr.push([ w.keyword, w.keyword ])
    end
    @categories["検索ワード"] = @select_word_arr

    # ページ共通セレクトボックス
    @select_word_for_bedroom= AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    @select_word_arr = []
    @select_word_for_bedroom.each do |w|
      @select_word_arr.push([ w.page_title, w.page_title ])
    end
    @categories["人気ページ"] = @select_word_arr

    ## 人気ページテーブルを生成
    @favorite_pages = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_favorite_page_table_for(@select_word_for_bedroom, @favorite_pages)
    # 理想値
    cond[:filters] = {
      :goal1_completions.gte => 1,
      :medium.matches => 'organic'
     }
    @select_word_for_bedroom_good = AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    put_skeleton_favorite_page_table_for(@select_word_for_bedroom_good, @favorite_pages, :good)
    total_view = 0
    total_top_view = 0
    counter = 0
    # 現状値
    cond[:filters] = {
      :goal1_completions.lt => 1,
      :medium.matches => 'organic'
    }
    @select_word_for_bedroom_bad = AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    put_skeleton_favorite_page_table_for(@select_word_for_bedroom_bad, @favorite_pages, :bad)
    total_view = 0
    total_top_view = 0
    counter = 0
    # GAP値
    @favorite_pages.each do |k, v|
      v[:gap] = (v[:bad].to_f - v[:good].to_f)
    end

    render :layout => 'ganalytics', :action => "show"
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @title = '全体'
    @user = User.find(params[:id])
    @narrow_action = user_path
    @from = Date.today.to_s
    @to = Date.today.next_month.to_s
    if params[:from].present?
      @from = params[:from]
    end
    if params[:to].present?
      @to = params[:to]
    end

    cond = {
        :start_date => Time.parse(@from),
        :end_date   => Time.parse(@to)
        # :start_date => Time.parse("2012-12-05"),
        # :end_date   => Time.parse('2013-01-05')
    }

    narrow_word = params[:narrow_select]

    case params[:device]
    when "pc"
      device = { :device_caategory.matches => 'desktop' }
      cond[:filters]
        # cond2 = {:filters    => { :medium.matches => 'organic' }}
    when "sphone"
      cond[:filters] = {
        :device_category.matches => 'mobile',
        :mobile_input_selector.matches => 'touchscreen'
      }
    when "mobile"
      cond[:filters] = {
        :device_category.matches => 'mobile',
        :mobile_input_selector.does_not_match => 'touchscreen'
      }
    end

    case params[:visitor]
    when "new"
      visitor_type = {:user_type.matches => 'New Visitor'}
    when "repeat"
      visitor_type = {
        :user_type.matches => 'Returning Visitor'
      }
    end

    # 部分テンプレートを変更しないので、空テンプレートを記載
    @render_action = 'norender'
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)

    ## ページ共通のテーブルを生成
    @not_gap_data_for_kitchen = AnalyticsServiceClass::NotGapDataForKitchen.results(ga_profile, cond)
    @nogap_tables = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_nogap_table(@nogap_tables)
    @not_gap_data_for_kitchen.each do |t|
      @nogap_tables[:pv] = t.pageviews
      @nogap_tables[:session] = t.sessions
      @nogap_tables[:cv] = t.goal1_completions
      @nogap_tables[:cvr] = t.goal1_conversion_rate
      @nogap_tables[:bounce_rate] = t.bounce_rate
    end

    ## 絞り込みセレクトボックス項目を生成
    @categories = {}
    # ページ共通セレクトボックス
    @select_word_for_bedroom= AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    @select_word_arr = []
    @select_word_for_bedroom.each do |w|
      @select_word_arr.push([ w.page_title, w.page_title ])
    end
    @categories["人気ページ"] = @select_word_arr

    ## 平均PV数 ~ リピート率テーブルを生成
    @gap_tables = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_gap_table(@gap_tables)
    # 総PV数の取得（リピート率計算用
    all_pv = 0
    @not_gap_data_for_kitchen.each do |t|
      all_pv = t.pageviews
    end
    cond[:filters] = { :goal1_completions.gte => 1 }
    @gap_data_for_kitchen_good = AnalyticsServiceClass::GapDataForKitchen.results(ga_profile, cond)
    cond[:filters] = {
      :goal1_completions.gte => 1,
      :user_type.matches => 'Returning Visitor'
    }
    @gap_repeat_data_for_kitchen_good = AnalyticsServiceClass::GapRepeatDataForKitchen.results(ga_profile, cond)
    if @gap_data_for_kitchen_good.total_results != 0 then
      @gap_data_for_kitchen_good.each do |t|
        @gap_tables[:avg_pv][:good] = t.pageviews_per_session
        @gap_tables[:avg_duration][:good] = t.avg_session_duration
        @gap_tables[:new_percent][:good] = t.percent_new_sessions
      end
    end
    if @gap_repeat_data_for_kitchen_good.total_results != 0 then
      @gap_repeat_data_for_kitchen_good.each do |t|
        @gap_tables[:repeat_rate][:good] = ( t.sessions.to_f / all_pv.to_f ) * 100
      end
    end
    # 現状値
    cond[:filters] = { :goal1_completions.lt => 1 }
    @gap_data_for_kitchen_bad = AnalyticsServiceClass::GapDataForKitchen.results(ga_profile, cond)
    cond[:filters] = {
      :goal1_completions.lt => 1,
      :user_type.matches => 'Returning Visitor'
    }
    @gap_repeat_data_for_kitchen_bad = AnalyticsServiceClass::GapRepeatDataForKitchen.results(ga_profile, cond)
    if @gap_data_for_kitchen_bad.total_results != 0 then
      @gap_data_for_kitchen_bad.each do |t|
        @gap_tables[:avg_pv][:bad] = t.pageviews_per_session
        @gap_tables[:avg_duration][:bad] = t.avg_session_duration
        @gap_tables[:new_percent][:bad] = t.percent_new_sessions
      end
    end
    if @gap_repeat_data_for_kitchen_bad.total_results != 0 then
      @gap_repeat_data_for_kitchen_bad.each do |t|
        @gap_tables[:repeat_rate][:bad] = ( t.sessions.to_f / all_pv.to_f ) * 100
      end
    end
    # GAP値
    @gap_tables[:avg_pv][:gap] = @gap_tables[:avg_pv][:bad].to_f - @gap_tables[:avg_pv][:good].to_f
    @gap_tables[:avg_duration][:gap] = @gap_tables[:avg_duration][:bad].to_f - @gap_tables[:avg_duration][:good].to_f
    @gap_tables[:new_percent][:gap] = @gap_tables[:new_percent][:bad].to_f - @gap_tables[:new_percent][:good].to_f
    @gap_tables[:repeat_rate][:gap] = @gap_tables[:repeat_rate][:bad].to_f - @gap_tables[:repeat_rate][:good].to_f

    #平均滞在時間の書式を変更
    # (@gap_tables[:avg_duration][:gap].to_i / 60)
    # (@gap_tables[:avg_session_duration][:gap].to_i % 60)

    ## 人気ページテーブルを生成
    @favorite_pages = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_favorite_page_table_for(@select_word_for_bedroom, @favorite_pages)
    # 理想値
    cond[:filters] = { :goal1_completions.gte => 1 }
    @select_word_for_bedroom_good = AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    put_skeleton_favorite_page_table_for(@select_word_for_bedroom_good, @favorite_pages, :good)
    total_view = 0
    total_top_view = 0
    counter = 0
    # 現状値
    cond[:filters] = { :goal1_completions.lt => 1 }
    @select_word_for_bedroom_bad = AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    put_skeleton_favorite_page_table_for(@select_word_for_bedroom_bad, @favorite_pages, :bad)
    total_view = 0
    total_top_view = 0
    counter = 0
    # GAP値
    @favorite_pages.each do |k, v|
      v[:gap] = (v[:bad].to_f - v[:good].to_f)
    end

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

    # ビュー用に共通ギャップ値なしテーブルスケルトンを作成

    def create_skeleton_nogap_table(result_hash)
      result_hash[:pv] = 0
      result_hash[:session] = 0
      result_hash[:cv] = 0
      result_hash[:cvr] = 0
      result_hash[:bounce_rate] = 0
      return result_hash
    end

    # ビュー用に共通ギャップ値テーブルスケルトンを作成

    def create_skeleton_gap_table(result_hash)
      [:good, :bad, :gap].each do |t|
        result_hash[:avg_pv][t] = 0
        result_hash[:avg_duration][t] = 0
        result_hash[:new_percent][t] = 0
        result_hash[:repeat_rate][t] = 0
      end
      return result_hash
    end

    # ビュー用に人気ページテーブルの生成

    def create_skeleton_favorite_page_table_for(input_hash, result_hash)
      counter = 0
      # @favorite_pages = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      input_hash.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
        counter += 1
        result_hash[t.page_title + ";;" + t.page_path][:good] = 0
        result_hash[t.page_title + ";;" + t.page_path][:bad] = 0
        result_hash[t.page_title + ";;" + t.page_path][:gap] = 0
        result_hash[t.page_title + ";;" + t.page_path][:index] = counter
        if counter >= 10 then
          break
        end
      end
      result_hash["その他"][:good] = 0
      result_hash["その他"][:bad] = 0
      result_hash["その他"][:gap] = 0
      result_hash["その他"][:index] = counter + 1
      return result_hash
    end


    def put_skeleton_favorite_page_table_for(gaapi_results, result_hash, good_or_bad)
      total_view = 0
      total_top_view = 0
      counter = 0

      if gaapi_results.total_results != 0
        gaapi_results.each do |t|
          total_view += t.pageviews.to_i
        end
        gaapi_results.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
          counter += 1
          result_hash[t.page_title + ";;" + t.page_path][good_or_bad] = t.pageviews.to_i
          if counter >= 10 then
            break
          end
        end
        result_hash.each do |k,v|
          total_top_view += v[good_or_bad].to_i
          v[good_or_bad] = ( v[good_or_bad].to_f / total_view.to_f ) * 100 # 人気ページ毎のPV（パーセント）
        end
        result_hash["その他"][good_or_bad] = ( ( total_view.to_i - total_top_view.to_i ).to_f / total_view.to_f ) * 100 # その他のパーセント
      end
      return result_hash
    end
end
