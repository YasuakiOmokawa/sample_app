require('rails_helper')
require "retryable"
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils, ExcelFunc

describe Ast::Ganalytics::Garbs do
  before do
    @from = DateTime.parse('2014/11/1')
    @to = DateTime.parse('2014/12/1')
    @cond = {
      :start_date => @from,
      :end_date   => @to,
      :filters => {},
    }
    @cv_num = 1
    @cv_txt = ('goal' + @cv_num.to_s + '_completions')
    create(:secret)
  end
  let(:project1) { create(:gaproject) }
  let(:user) { create(:multiple_test_user) }

  describe "Session" do
    before do
      gaservice = Ast::Ganalytics::Garbs::Session.new
      @session = gaservice.login_multi(project1.id)
      @ga_profile = gaservice.load_profile(@session, user)
    end

    it "セッションが正常に作れること" do
      expect(@session).to be_truthy
    end

    it "プロファイルが正常に作れること" do
      expect(@ga_profile).to be_truthy
    end
  end

  describe "Cond" do

    it "正常に読み込まれること" do
      cond_res = Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res
      expect(cond_res).to be_truthy
      expect(cond_res[:limit]).to eq(10)
    end
  end

  describe "Data" do
    before do
      gaservice = Ast::Ganalytics::Garbs::Session.new
      @session = gaservice.login_multi(project1.id)
      @ga_profile = gaservice.load_profile(@session, user)
    end

    it "データが取得できること" do
      res = Ast::Ganalytics::Garbs::Data.create_class("TestGarb",
          [ :pageviews], [:date] ).results(@ga_profile, @cond)

      expect(res).to be_truthy
    end

    it "集約データの取得ができること" do
      metricses = [
        :pageviews,
        :pageviewsPerSession,
        :sessions,
        :avgSessionDuration,
        :bounceRate,
        :percentNewSessions,
        :users,
        :Goal1Completions
      ]
        for_graph = Ast::Ganalytics::Garbs::Data.create_class('SUM',
          metricses, [:date] ).results(@ga_profile, @cond)

      expect(for_graph).to be_truthy
    end

    it "収集データを加工できること" do
      metrics = Metrics.new()
      metrics_camel_case_datas = metrics.garb_parameter
      @metrics_snake_case_datas = metrics.garb_result
      metrics_for_graph_merge = metrics.jp_caption
      site_data = Ast::Ganalytics::Garbs::Data.create_class('SUM',
        metrics_camel_case_datas.dup.push(:Goal1Completions), [:date] ).results(@ga_profile, @cond)

      @ast_data = site_data.reduce([]) do |acum, item|
        item.day_type = chk_day(item.date.to_date)
        item.repeat_rate = item.sessions.to_i > 0 ? (100 - item.percent_new_sessions.to_f).round(1).to_s : "0"
        acum << item
      end
      expect(@ast_data).to be_truthy
    end

    it "人気ページ用CVデータを取得できること" do
      cved_data = Ast::Ganalytics::Garbs::Data.create_class('CvedSession',
        [:sessions], [:pagePath]).results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).cved!.res)
      expect(cved_data).to be_truthy
    end

    it "人気ページ用GAPデータを取得できること" do
      fav_gap = fetch_analytics_data('FetchKeywordForPages', @ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).res, @cv_txt)
      expect(fav_gap).to be_truthy
    end

    it "人気ページ用スケルトンデータを取得できること" do
      fav_for_skel = Ast::Ganalytics::Garbs::Data::FetchKeywordForPages.results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:sessions).cved!.res)
      expect(fav_for_skel).to be_truthy
    end

    it "ランディングページ用データを取得できること" do
      land_for_skel = Ast::Ganalytics::Garbs::Data::FetchKeywordForLanding.results(@ga_profile, Ast::Ganalytics::Garbs::Cond.new(@cond, @cv_txt).limit!(5).sort_desc!(:bounceRate).res)
      expect(land_for_skel).to be_truthy
    end

    it "全てのセッションデータが取得できること" do
      ga_result = Ast::Ganalytics::Garbs::Data.create_class('AllSession', [:sessions], []).results(@ga_profile, @cond)
      expect(ga_result). to be_truthy
    end
  end
end
