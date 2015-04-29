require('rails_helper')

describe Content do

  let(:zero_content) {build(:zero_content)}

  it "データが3行以上ないとエラーになること" do
    zero_content.valid?
    expect(zero_content.errors[:upload_file]
      ).to include('データ数は3行以上にしてください')
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
