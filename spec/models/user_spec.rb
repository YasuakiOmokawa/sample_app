require('rails_helper')

describe 'User' do

  describe "複数項目の一括登録テスト" do

    after(:all) { User.delete_all }

    it "ファクトリが有効であること" do
      expect(build(:user)).to be_valid
    end

    it "validateするメソッドで、対象項目の異常値更新をはじけること" do
      tmp = 'o' * 51
      vega = build(:user, name: tmp)
      vega.valid?
      expect(vega.errors.size).to eql(1)
    end
  end
end
