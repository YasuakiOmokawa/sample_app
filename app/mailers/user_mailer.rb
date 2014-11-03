class UserMailer < ActionMailer::Base
  default from: "analyze_complete@senk-inc.co.jp"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    # @greeting = "Hi"
    @user = user

    mail :to => user.email, :subject => "【TAS for GA】パスワードをリセット"
  end

  def send_message_for_complete_analyze(user)
    @user = user

    mail :to => user.email, :subject => "分析完了のお知らせ"
  end
end
