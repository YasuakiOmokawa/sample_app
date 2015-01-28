include ApplicationHelper

def sign_in(user, options={})
  if options[:no_capybara]
    # Capybaraを使用していない場合にもサインインする。
    remember_token = User.new_remember_token
    cookies[:remember_token] = remember_token
    user.update_attribute(:remember_token, User.encrypt(remember_token))
  else
    visit signin_path
    fill_in "session[email]",    with: user.email
    fill_in "session[password]", with: user.password
    click_link('ログイン')
  end
end
