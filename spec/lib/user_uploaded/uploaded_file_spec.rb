require('rails_helper')

describe UserUploaded::UploadedFile do

  before(:all) do
   csv_path =  Rails.root.join('spec', 'fixtures', 'meisai.csv').to_s
   @uploaded_file = UserUploaded::UploadedFile.new(csv_path)
  end

  describe "データ読み込み" do

    it "データが読み込まれること" do
      expect(@uploaded_file).to be_truthy
    end
  end

end
