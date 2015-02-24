require 'spec_helper'

describe AnalyticsService do
  before(:all) {
    @secret = FactoryGirl.create(:secret)
  }
  after(:all) { @secret.destroy }
  let(:user1) { create(:gaproject) }

  describe "実行前データの存在確認" do
    it "暗号化テーブルが存在すること" do
      expect(Secret.find(1)).to be_valid
    end

    it "gaprojectが存在すること" do
      expect(user1.proj_owner_email).to eq("senk_example@senk-inc.co.jp")
    end
  end
end
