require 'holiday_japan'

class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def search
    @user = User.find(params[:id])
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
        :end_date   => Time.parse(@to),
        :filters    => { :medium.matches => 'organic' }
    }
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)

    # ページ固有設定
    @title = '検索'
    @narrow_action = search_user_path
    # 絞り込み条件が「人気ページ」以外だった場合、部分テンプレートを変更する
    @narrow_word = params[:narrow_select]
    @render_action = 'search'

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




    # ◆ ページ共通のテーブルを生成
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
    ## 平均PV数 ~ リピート率テーブルを生成
    @gap_tables = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_gap_table(@gap_tables)
    # 総セッション数の取得（リピート率計算用
    all_sessions = 0
    @not_gap_data_for_kitchen.each do |t|
      all_sessions = t.sessions
    end
    cond[:filters] = {
      :goal1_completions.gte => 1,
      :medium.matches => 'organic'
    }
    @gap_data_for_kitchen_good = AnalyticsServiceClass::GapDataForKitchen.results(ga_profile, cond)
    cond[:filters] = {
      :goal1_completions.gte => 1,
      :user_type.matches => 'Returning Visitor',
      :medium.matches => 'organic'
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
        @gap_tables[:repeat_rate][:good] = ( t.sessions.to_f / all_sessions.to_f ) * 100
      end
    end
    # 現状値
    cond[:filters] = {
      :goal1_completions.lt => 1,
      :medium.matches => 'organic'
    }
    @gap_data_for_kitchen_bad = AnalyticsServiceClass::GapDataForKitchen.results(ga_profile, cond)
    cond[:filters] = {
      :goal1_completions.lt => 1,
      :user_type.matches => 'Returning Visitor',
      :medium.matches => 'organic'
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
        @gap_tables[:repeat_rate][:bad] = ( t.sessions.to_f / all_sessions.to_f ) * 100
      end
    end
    # GAP値
    @gap_tables[:avg_pv][:gap] = @gap_tables[:avg_pv][:bad].to_f - @gap_tables[:avg_pv][:good].to_f
    @gap_tables[:avg_duration][:gap] = @gap_tables[:avg_duration][:bad].to_f - @gap_tables[:avg_duration][:good].to_f
    @gap_tables[:new_percent][:gap] = @gap_tables[:new_percent][:bad].to_f - @gap_tables[:new_percent][:good].to_f
    @gap_tables[:repeat_rate][:gap] = @gap_tables[:repeat_rate][:bad].to_f - @gap_tables[:repeat_rate][:good].to_f

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
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)
    @favorite_pages.each do |k, v|
d      v[:gap] = (v[:bad].to_f - v[:good].to_f)
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
    @from = Date.today
    @to = Date.today.next_month
    if params[:from].present?
      from_y, from_m, from_d = params[:from].split("-")
      @from = Date.new(from_y.to_i, from_m.to_i, from_d.to_i)
    end
    if params[:to].present?
      to_y, to_m, to_d = params[:to].split("-")
      @to = Date.new(to_y.to_i, to_m.to_i, to_d.to_i)
    end

    cond = {
        :start_date => @from,
        :end_date   => @to
        # :start_date => Time.parse("2012-12-05"),
        # :end_date   => Time.parse('2013-01-05')
    }
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)
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

    ## 絞り込みセレクトボックス項目を生成
    @categories = {}
    # ページ共通セレクトボックス
    @select_word_for_bedroom= AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    @select_word_arr = []
    @select_word_for_bedroom.each do |w|
      @select_word_arr.push([ w.page_title, w.page_title ])
    end
    @categories["人気ページ"] = @select_word_arr

    # ◆グラフ生成用のテーブルを作成
    # テーブル項目の配列
    columns_for_graph = [
      :pageviews,
      :sessions,
      :pageviews_per_session,
      :avg_session_duration,
      :percent_new_sessions,
      :bounce_rate
    ]
    @gap_tables_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_for_graph(@gap_tables_for_graph, @from, @to, columns_for_graph)
    # CV値を挿入
    @cv_for_graph = AnalyticsServiceClass::CVForGraphSkeleton.results(ga_profile, cond)
    put_cv_for_graph(@cv_for_graph, @gap_tables_for_graph)
    # 理想値
    cond[:filters] = { :goal1_completions.gte => 1 }
    @gap_data_for_graph_good = AnalyticsServiceClass::GapDataForGraph.results(ga_profile, cond)
    put_table_for_graph(@gap_data_for_graph_good, @gap_tables_for_graph)
    # 現実値
    cond[:filters] = { :goal1_completions.lt => 1 }
    @gap_data_for_graph_bad = AnalyticsServiceClass::GapDataForGraph.results(ga_profile, cond)
    put_table_for_graph(@gap_data_for_graph_bad, @gap_tables_for_graph)
    # GAP値
    calc_gap_for_graph(@gap_tables_for_graph, columns_for_graph)

    # ◆グラフ表示プログラム用に配列を作成
    @arr_for_graph = []
    @hash_for_graph = Hash.new{ |h,k| h[k] = {} }
    create_array_for_graph(@hash_for_graph, @gap_tables_for_graph)
    gon.hash_for_graph = @hash_for_graph


    # ◆曜日別の値を出すテーブルを作成
    @value_table_by_days = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_table_by_days(@value_table_by_days, @gap_tables_for_graph)


    #　◆ページ共通のテーブルを生成
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
    ## 平均PV数 ~ リピート率テーブルを生成
    @gap_tables = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    create_skeleton_gap_table(@gap_tables)
    # 総PV数の取得（リピート率計算用
    all_sessions = 0
    @not_gap_data_for_kitchen.each do |t|
      all_sessions = t.sessions
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
        @gap_tables[:repeat_rate][:good] = ( t.sessions.to_f / all_sessions.to_f ) * 100
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
        @gap_tables[:repeat_rate][:bad] = ( t.sessions.to_f / all_sessions.to_f ) * 100
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

    # ビュー用にグラフ値テーブルスケルトンを作成

    def create_skeleton_for_graph(result_hash, from_date, to_date, columns)
      idx = 1
      (from_date..to_date).each do |t|
      columns.each do |u|
          dts = t.to_s.gsub( /-/, "" )
          if (t.wday == 0 or t.wday == 6) or HolidayJapan.check(t) then
            result_hash[dts][u] = [0, 0, 0, 'day_off']
          else
            result_hash[dts][u] = [0, 0, 0, 'day_on']
          end
          result_hash[dts][:cv] = 0
          result_hash[dts]["idx"] = idx
      end
      idx += 1
      end
      return result_hash
    end

    # ビュー用にグラフ値テーブルへ値を代入

    def put_table_for_graph(data, table)
      if data.total_results != 0 then
        good_or_bad = 0
        data.each do |d|
          date = d.date
          if data =~ /good/ then
            good_or_bad = 0
          else
            good_or_bad = 1
          end
          table[date][:pageviews][good_or_bad] = d.pageviews
          table[date][:sessions][good_or_bad] = d.sessions
          table[date][:pageviews_per_session][good_or_bad] = d.pageviews_per_session
          table[date][:avg_session_duration][good_or_bad] = d.avg_session_duration
          table[date][:percent_new_sessions][good_or_bad] = d.percent_new_sessions
          table[date][:bounce_rate][good_or_bad] = d.bounce_rate
        end
      end
      return table
    end

    # グラフ値テーブルのGAP値を計算

    def calc_gap_for_graph(table, columns)
      table.each do |k, v|
        date = k.to_s # きちんと変換してやんないとnilClass エラーになるので注意
        columns.each do |u|
          table[date][u][2] = table[date][u][1].to_f - table[date][u][0].to_f
        end
      end
      return table
    end

    # グラフ値テーブルへcv値を代入
    def put_cv_for_graph(data, table)
      if data.total_results != 0 then
        data.each do |d|
          date = d.date
          table[date][:cv] = d.goal1_completions
        end
      end
      return table
    end

    # 曜日別の値を出すテーブルを作成
    def create_table_by_days(table, data)
      [:day_on, :day_off].each do |t|
        [:good, :bad, :gap].each do |u|
          table[t][u] = 0
        end
      end
      data.each do |k, v|
        if v[:pageviews][3] == 'day_on' then
          table[:day_on][:good] += v[:pageviews][0].to_i
          table[:day_on][:bad] += v[:pageviews][1].to_i
          table[:day_on][:gap] += v[:pageviews][2].to_i
        else
          table[:day_off][:good] += v[:pageviews][0].to_i
          table[:day_off][:bad] += v[:pageviews][1].to_i
          table[:day_off][:gap] += v[:pageviews][2].to_i
        end
      end
      return table
    end

    # グラフテーブルからグラフ表示プログラム用の配列を出力
    def create_array_for_graph(hash, table)
      table.sort_by{ |a, b| b[:idx].to_i }.each do |k, v|
        date =  k.to_i
        hash[date] = [ v[:pageviews][2], v[:cv].to_i ]
      end
      return hash
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
