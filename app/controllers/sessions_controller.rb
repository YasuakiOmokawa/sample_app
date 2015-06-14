class SessionsController < ApplicationController

  def new
    redirect_to user_path(current_user) and return if signed_in?
    render :layout => 'not_ga'
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      sign_in user
      # データベース容量の節約のため、ユーザがアップロードしたファイルの削除
      Content.where(user_id: current_user.id).delete_all
      # 管理者なら一覧画面へ
      redirect_to users_url and return if current_user.admin?
      redirect_back_or user
    else
      flash.now[:error] = 'IDかパスワードが間違っています'
      render 'new', :layout => 'not_ga'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
