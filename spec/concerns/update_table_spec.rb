require('rails_helper')

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

      it "ファイルから取得した値を格納すること" do
        @content = upldedanlyzstatuseshelper.active_content(user.id)
        @content.upload_file.shift unless @content.nil?
        updatetable.replace_cv_with_custom(@content, @ast_data, @cv_txt)
        expect(@ast_data[0][@cv_txt.to_sym]).to eq("100")
      end
    end

  end
end
