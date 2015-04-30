require('rails_helper')

describe Content do

  let(:zero_content) {build(:zero_content)}
  let(:invalid_header_content) {build(:invalid_header_content)}
  let(:invalid_unmatch_content) {build(:invalid_unmatch_content)}
  let(:invalid_date_format_content) {build(:invalid_date_format_content)}
  let(:invalid_from_to_content) {build(:invalid_from_to_content)}

  it "データが3行以上ないとエラーになること" do
    zero_content.valid?
    expect(zero_content.errors[:upload_file]
      ).to include('データ数は3行以上にしてください')
  end

  it "ヘッダの書式がdate, valueとなっていなければエラーとなること" do
    invalid_header_content.valid?
    expect(invalid_header_content.errors[:upload_file]
      ).to include('ヘッダ書式が間違っています')
  end

  it "日付、値の数が同一でなければエラーとなること" do
    invalid_unmatch_content.valid?
    expect(invalid_unmatch_content.errors[:upload_file]
      ).to include('日付と値の数は同じにしてください')
  end

  it "日付の書式が不正であればエラーとなること" do
    invalid_date_format_content.valid?
    expect(invalid_date_format_content.errors[:upload_file]
      ).to include('日付はYYYY/MM/DD形式にし、正しい日付を入力してください')
  end

  it "期間の指定が不正であればエラーとなること" do
    invalid_from_to_content.valid?
    expect(invalid_from_to_content.errors[:upload_file]
      ).to include('日付は連続データを入力し、開始日付は終了日付の前日にしてください')
  end

  it "アップロードデータを取得できること" do
    create(:valid_content)
    content = Content.where(user_id: 1
      ).reduce({}) do |acum, item|
      acum[item.upload_file_name] = item.user_id
      acum
    end
    expect(content['valid_file']).to eq(1)
  end

  it "存在しないデータを指定したら空ハッシュで返却すること" do
    content = Content.where(user_id: 0
      ).reduce({}) do |acum, item|
      acum[item.user_id] = item.upload_file_name
      acum
    end
    expect(content).to be {}
    expect(content.size).to eq(0)
  end

end
