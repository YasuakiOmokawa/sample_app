class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def search
    @title = '検索'
    @user = User.find(params[:id])
    @narrow_action = search_user_path
    # 絞り込み条件が「人気ページ」以外だった場合、部分テンプレートを変更する
    @render_action = 'search'
    analytics = AnalyticsService.new
    ga_profile = analytics.load_profile(@user)
    cond = {
        :start_date => Time.parse("2012-12-05"),
        :end_date   => Time.parse('2013-01-05'),
        :filters    => { :medium.matches => 'organic' }
    }
    @not_gap_data_for_kitchen = AnalyticsServiceClass::NotGapDataForKitchen.results(ga_profile, cond)
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
        :end_date   => Time.parse('2013-01-05'),
        # :filters    => { :medium.matches => 'organic' }
    }
    @not_gap_data_for_kitchen = AnalyticsServiceClass::NotGapDataForKitchen.results(ga_profile, cond)
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
