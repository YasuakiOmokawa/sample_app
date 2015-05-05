require('rails_helper')

require 'user_func'
include ParamUtils

describe UpdateTable do
  let(:test_class) { Struct.new(:updatetable) { include UpdateTable } }
  let(:updatetable) { test_class.new }
  let(:test_class2) { Struct.new(:upldedanlyzstatuseshelper) { include UpldedAnlyzStatusesHelper } }
  let(:upldedanlyzstatuseshelper) { test_class2.new }

  describe ".replace_cv_with_custom" do
    before do
      require('pstore')
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ast_data = garb[:ast_data]
        @reduce_naver = garb[:reduce_naver]
      }
      create(:secret)
      create(:valid_content)
      create(:status_for_user_id1)
      @cv_num = 1
      @cv_txt = ('goal' + @cv_num.to_s + '_completions')
    end
    let(:user) {create(:multiple_test_user)}
    let(:no_upload_user) {create(:no_upload_user)}

    context "カスタム分析対象の場合" do
      before do
        @content = upldedanlyzstatuseshelper.active_content(user.id)
        @content.upload_file.shift unless @content.nil?
      end

      it "ファイルから取得した値を格納すること(@ast_data)" do
        updatetable.replace_cv_with_custom(@content, @ast_data, @cv_txt)

        expect(@ast_data[0][@cv_txt.to_sym]).to eq("100")
        expect(@ast_data[30][@cv_txt.to_sym]).to eq("130")
        expect(@ast_data.size).to eq(31)
      end

      it "ファイルから取得した値を格納すること(@reduce_naver)" do
        updatetable.replace_cv_with_custom(@content, @reduce_naver, @cv_txt)

        expect(@reduce_naver[0][@cv_txt.to_sym]).to eq("101")
        expect(@reduce_naver[5][@cv_txt.to_sym]).to eq("121")
        expect(@reduce_naver.size).to eq(6)
      end
    end

    context "カスタム分析対象ではない場合" do
      before do
        @content = upldedanlyzstatuseshelper.active_content(no_upload_user.id)
        @content.upload_file.shift unless @content.nil?
      end

      it "データに変化がないこと(@ast_data)" do
        updatetable.replace_cv_with_custom(@content, @ast_data, @cv_txt)
        expect(@ast_data[0][@cv_txt.to_sym]).to eq("1")
        expect(@ast_data[30][@cv_txt.to_sym]).to eq("1")
        expect(@ast_data.size).to eq(31)
      end

      it "データに変化がないこと(@reduce_naver)" do
        updatetable.replace_cv_with_custom(@content, @reduce_naver, @cv_txt)

        expect(@reduce_naver[0][@cv_txt.to_sym]).to eq("0")
        expect(@reduce_naver[5][@cv_txt.to_sym]).to eq("0")
        expect(@reduce_naver.size).to eq(6)
      end
    end
  end
end
