require('rails_helper')

describe ContentsController do
  before { create(:secret) }
  let(:user) {create(:multiple_test_user)}

  describe "visit show" do

    context "ログインしている場合", js: true do
      it "ファイルアップロード画面が表示されること" do
        visit root_path
        fill_in 'session_email', with: user.email
        fill_in 'session_password', with: user.password
        click_on 'ログイン'
        # ↓home画面
        click_on 'アップロード'
        expect(page).to have_title('ファイルアップロード')
        expect(page).to have_content('アップロード')
      end
    end

    context "ログインしていない場合" do
      it "ログインを促すこと" do
        visit content_path(user)
        expect(page).to have_content('ログインしてください')
      end
    end
  end

  describe "upload file", js: true do
    it "ファイルを選択しない場合は失敗すること" do
      sign_in(user)
      visit content_path(user)
      click_on 'アップロード'
      expect(page).to have_title('ファイルアップロード')
    end
  end
end
