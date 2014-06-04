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

    # ページ共通
    @select_word_for_bedroom_good= AnalyticsServiceClass::FetchKeywordForPages.results(ga_profile, cond)
    @select_word_arr = []
    @select_word_for_bedroom.each do |w|
      @select_word_arr.push([ w.page_title, w.page_title ])
    end
    @categories["人気ページ"] = @select_word_arr

    render :layout => 'ganalytics', :action => "show"
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @title = '全体'
    @user = User.find(params[:id])
    @narrow_action = user_path
    # 部分テンプレートを変更しないので、空テンプレートを記載
    @render_action = 'norender'
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)
    cond = {
        :start_date => Time.parse("2012-12-05"),
        :end_date   => Time.parse('2013-01-05')
    }

    ## ページ共通のテーブルを生成
    @not_gap_data_for_kitchen = AnalyticsServiceClass::NotGapDataForKitchen.results(ga_profile, cond)

    ## 絞り込みセレクトボックス項目を生成
    @categories = {}
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
