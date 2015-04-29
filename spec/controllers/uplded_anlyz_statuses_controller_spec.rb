require 'rails_helper'

RSpec.describe UpldedAnlyzStatusesController, type: :controller do
  before do
    create(:secret)
    create(:valid_content)
  end
  let(:user) {create(:multiple_test_user)}
  let(:no_upload_user) {create(:no_upload_user)}

  describe "分析開始" do

    context "ファイルが存在しない合", js: true do
      it "分析リンクが存在しないこと" do
        sign_in(no_upload_user)
        visit root_path
        expect(page.has_link?('カスタム分析')).to be_falsey
      end
    end
  end

end
