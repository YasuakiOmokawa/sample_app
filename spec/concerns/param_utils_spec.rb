require('rails_helper')

describe ParamUtils do
  let(:test_class) { Struct.new(:paramutils) { include ParamUtils } }
  let(:paramutils) { test_class.new }
  let(:test_class2) { Struct.new(:upldedanlyzstatuseshelper) { include UpldedAnlyzStatusesHelper } }
  let(:upldedanlyzstatuseshelper) { test_class2.new }

  describe ".set_date_format" do
    it "文字列を渡すと日付オブジェクトを生成できること" do
      expect(paramutils.set_date_format("2015/3/20")
        ).to be_an_instance_of Date
    end
  end

  describe ".set_from_to" do
    before do
      create(:secret)
      create(:valid_content)
      create(:status_for_user_id1)
    end
    let(:user) {create(:multiple_test_user)}
    let(:no_upload_user) {create(:no_upload_user)}

    context "オフラインデータ対象の場合" do

      it "ファイルから取得した日付を返却すること" do
        params = {}
        @content = Content.find()
        @content.upload_file.shift unless @content.nil?
        (@from, @to) = paramutils.set_from_to(@content, params)
        expect(@from).to eq(paramutils.set_date_format("2014/11/1"))
        expect(@to).to eq(paramutils.set_date_format("2014/12/1"))
      end
    end

    context "オフラインデータ対象でない場合" do

      it "現在時刻を返却すること" do
        params = {}
        @content = upldedanlyzstatuseshelper.active_content(no_upload_user.id)
        @content.upload_file.shift unless @content.nil?
        (@from, @to) = paramutils.set_from_to(@content, params)
        expect(@from).to eq(Date.today.prev_month)
        expect(@to).to eq(Date.today)
      end
    end
  end

  describe ".set_key_for_data_cache" do
    before do
      create(:secret)
      create(:valid_content)
      create(:status_for_user_id1)
    end
    let(:user) {create(:multiple_test_user)}
    let(:no_upload_user) {create(:no_upload_user)}

    context "オフラインデータ対象の場合" do

      it "アクティブなContentの id をパラメータに付与できること" do
        @content = upldedanlyzstatuseshelper.active_content(user.id)
        hoge = paramutils.set_key_for_data_cache("hoge", @content)
        expect(hoge).to include("&custom_id=")
      end
    end

    context "オフラインデータ対象でない場合" do

      it "入力パラメータと同じデータを返却すること" do
        @content = upldedanlyzstatuseshelper.active_content(no_upload_user.id)
        hoge = paramutils.set_key_for_data_cache("hoge", @content)
        expect(hoge).to eq("hoge")
      end
    end
  end

  describe ".padding_date_format" do

    it "パディングされた日付を返すこと" do
      a = "2014/4/1"
      expect(paramutils.padding_date_format(a)).to eq("2014/04/01")
    end

    it "パディングされてたらそのままの値を返すこと" do
      a = "2014/04/01"
      expect(paramutils.padding_date_format(a)).to eq("2014/04/01")
    end
  end
end
