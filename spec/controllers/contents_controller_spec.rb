require('rails_helper')

describe ContentsController do
  before do
    create(:secret)
    create(:valid_content)
  end
  let(:user) {create(:multiple_test_user)}
  let(:no_upload_user) {create(:no_upload_user)}

  describe "visit show" do

    context "ログインしている場合", js: true do
      it "ファイルアップロード画面が表示されること" do
        sign_in(user)
        visit root_path
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
      expect(page).to have_content('Upload fileを入力してください')
    end
  end

    describe "アップロードダイアログのリストボックスが正常であること", js: true do
      context "アップロードファイルが存在する場合" do
        it "リストボックスに値が存在すること" do
          sign_in(user)
          visit root_path
          expect(page).to have_select(
            'uplded_anlyz_status[content_id]', selected: 'valid_file')
        end
      end

      context "アップロードファイルが存在しない場合" do
        it "リストボックスに値が存在しないこと" do
          sign_in(no_upload_user)
          visit root_path
          expect(page).to have_select(
            'uplded_anlyz_status[content_id]', selected: [])
        end
      end
    end

end
