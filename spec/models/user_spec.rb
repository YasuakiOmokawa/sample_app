require 'spec_helper'

describe 'User' do

  describe "複数項目の一括登録テスト" do

    before { FactoryGirl.create(:user) }
    after { User.delete_all }
    let(:user) { User.where(email: 'michael@example.com').first }

    it "DB登録されてること" do
      expect(user.email).to eq('michael@example.com')
    end

    it "validate対象ではない単項目を更新できること" do
      user.update_attributes({gaproperty_id: 'TEST'})
      expect(user).to be_valid
    end

    it "name項目の異常値更新をはじけること" do
      tmp = 'o' * 51
      user.update_attribute(:name, tmp)
      expect(user).not_to be_valid
    end
  end
end
