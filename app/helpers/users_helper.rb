module UsersHelper

  # 与えられたユーザーのGravatar (http://gravatar.com/) を返す。
  def gravatar_for(user, options = { size: 50 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  def get_postfix
    if @day_type == 'day_on'
      postfix = '__day_on'
    elsif @day_type == 'day_off'
      postfix = '__day_off'
    else
      postfix = ''
    end
  end

  def get_gafooter_text
    'Copyright (C) 2015 senk Inc. All Rights Reserved.'
  end

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
end
