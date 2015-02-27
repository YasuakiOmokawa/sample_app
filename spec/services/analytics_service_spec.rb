require 'spec_helper'

describe AnalyticsService do
  before(:all) {
    @secret = FactoryGirl.create(:secret)
  }
  after(:all) { @secret.destroy }
  let(:project1) { create(:gaproject) }
  let(:project2) { create(:gaproject2) }
  let(:user) { create(:multiple_test_user) }
  let(:user2) { create(:multiple_test_user2) }

  describe "実行前データの存在確認" do
    it "暗号化テーブルが存在すること" do
      expect(Secret.find(1)).to be_valid
    end

    it "gaprojectが存在すること" do
      expect(project1.id).to eq(1)
    end

    it "対象ユーザが存在すること" do
      expect(user.gaproject_id).to eq(1)
    end
  end

  describe "garbデータ取得の確認" do
    before do
      analyticsservice = AnalyticsService.new
      @session = analyticsservice.login_multi(project1.id)
      @ga_profile = analyticsservice.load_profile(@session, user)
      @ga_profile2 = analyticsservice.load_profile(@session, user2)
      @session2 = analyticsservice.login_multi(project2.id)
      @from = DateTime.parse('2014/11/1')
      @to = DateTime.parse('2014/12/1')
      @cond = {
        :start_date => @from,
        :end_date   => @to,
        :filters => {},
      }
    end

    it "セッションが作れること" do
      expect(@session).to be_true
      expect(@session2).to be_true
    end

    it "プロファイルが作れること" do
      expect(@ga_profile).to be_true
      expect(@ga_profile2).to be_true
    end

    it "データが取れること" do
      res = Analytics.create_class("TestGarb",
          [ :pageviews], [:date] ).results(@ga_profile, @cond)
      res2 = Analytics.create_class("TestGarb",
          [ :pageviews], [:date] ).results(@ga_profile2, @cond)

      expect(res).to be_true
      expect(res2).to be_true
    end

    it "parallelジェムが正常に動作すること" do
      require('parallel')

      ds = %w(aiueo kakikukeko sasisuseso)
      Parallel.each(ds, in_threads: 3) { |d|
        puts d
      }
    end

    # it "データが並列で取れること" do
    #   require('parallel')

    #   arr = []
    #   multies = []
    #   multi = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    #   Multi = Struct.new(:number, :profile)
    #   multi.reduce([]) do |acum, number|
    #     acum << Multi.new(number, @ga_profile) if number < 8
    #     acum << Multi.new(number, @ga_profile2) if number >= 8
    #     multies = acum
    #   end

    #   ActiveSupport::Dependencies.require_or_load('analytics.rb')
    #   Parallel.each(multies, in_threads: 14) { |mul|
    #     cls = "Test#{mul.number}"
    #     res = Analytics.create_class(cls,
    #       [ :pageviews], [:date] ).results(mul.profile, @cond)
    #     arr.push(res)
    #   }
    #   expect(arr.size).to eq(14)
    # end

  end
end
