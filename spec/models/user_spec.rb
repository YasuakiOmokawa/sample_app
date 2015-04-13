require('rails_helper')

describe 'User' do

  describe "複数項目の一括登録テスト" do

    after(:all) { User.delete_all }

    it "ファクトリが有効であること" do
      expect(build(:user)).to be_valid
    end

    it "validateするメソッドで、対象項目の異常値更新をはじけること" do
      tmp = 'o' * 51
      expect(build(:user, name: tmp)).to have(1).errors_on(:name)
    end
  end
end
