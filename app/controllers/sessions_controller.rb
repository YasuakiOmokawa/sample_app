class SessionsController < ApplicationController

  def new
    redirect_to user_path(current_user) and return if signed_in?
    render :layout => false
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_to users_url and return if current_user.admin? # admin なら一覧画面へ
      redirect_back_or user
    else
      flash.now[:error] = 'IDかパスワードが間違っています'
      render 'new', :layout => false
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
