require 'spec_helper'

require 'holiday_japan'
require 'securerandom'
require "retryable"
require 'user_func'
require 'create_table'
require 'insert_table'
require 'update_table'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils, ExcelFunc

describe UsersController do
  before do
    require 'pstore'
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ga_profile = garb[:ga_profile]
        @ast_data = garb[:ast_data]
      }
      @cv_num = 1
  end

  describe "is_not_uniq?" do
    it "配列データが一意でなければtrueを返すこと" do
      d = %w(1.0 2.0 2.0)
      expect(is_not_uniq?(d)).to eq(true)
    end

    it "配列データが一意であればtrueを返さないこと" do
      d = %w(1.0 1.0 1.0)
      expect(is_not_uniq?(d)).not_to eq(true)
    end
  end

  describe "@valids" do
    it "validコレクションのメトリクスを削除したとき、newに渡した引数データが変化しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.metricses.delete(:sessions) if valid.day_type == 'all_day'
        valid.metricses.delete(:pageviews) if valid.day_type == 'day_on'
        valid.metricses.delete(:users) if valid.day_type == 'day_off'
        expect(@metrics_snake_case_datas.size).not_to eq(valid.metricses.size)
      end
    end

    it "validコレクションのメトリクスを削除したとき、互いのデータに干渉しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.metricses.delete(:sessions) if valid.day_type == 'all_day'
        valid.metricses.delete(:pageviews) if valid.day_type == 'day_on'
        valid.metricses.delete(:users) if valid.day_type == 'day_off'
      end
      @valids.each do |valid|
        if valid.day_type == 'all_day'
          expect(valid.metricses.include?(:pageviews)).to eq(true)
        elsif valid.day_type == 'day_on'
          expect(valid.metricses.include?(:users)).to eq(true)
        else
          expect(valid.metricses.include?(:sessions)).to eq(true)
        end
      end
    end

    it "validコレクションの日付を削除したとき、newに渡した引数データが変化しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.day_type.delete('all_day') if valid.day_type == 'all_day'
        expect(@valid_analyze_day_types.include?('all_day')).to eq(true)
      end
    end
  end

  describe "UserFunc" do

    describe "validate_cv" do

      it "validate対象データが呼ばれること" do
        expect(@ast_data[0].date).to eq('20141101')
      end

      it "CVバリデートし、全ての日付タイプが分析対象として残ること" do
        @valid_analyze_day_types = get_day_types
        validate_cv
        expect(@valid_analyze_day_types.size).to eq(3)
      end
    end

    describe "validate_metrics" do

      it "指標バリデートし、全日付タイプ全項目が分析対象として残ること" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result
        @valid_analyze_day_types = get_day_types
        @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create

        validate_metrics
        expect(@valids.map{|item| item.metricses.size}.sum).to eq(24)
      end

      it "異常指標が除外されること: 値の種類が１つしかない指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        data = %w(1.0 1.0) #異常用コード
        delete_uniq_metrics(data, :pageviews, @metrics_snake_case_datas)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end

      it "異常指標が除外されること: CVと指標の一意な組み合わせが少ない指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        cves = %w(1.0 1.0) #異常用コード
        data = %w(1.0 1.0) #異常用コード
        delete_invalid_metrics_multiple(data, :pageviews, @metrics_snake_case_datas, cves)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end

      it "異常指標が除外されること: ゼロが多すぎる指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        data = [1, 2, 0, 0, 0, 0, 0, 0, 0] #異常用コード
        delete_too_much_zero_metrics(data, :pageviews, @metrics_snake_case_datas)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end
    end
  end

  describe "分析の開始" do
    before do
      metrics = Metrics.new()
      @metrics_for_graph_merge = metrics.jp_caption
      @metrics_snake_case_datas = metrics.garb_result
      @bubble_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, 'all_day')
    end

    it "バブルチャート表示データを正常に算出できること" do
      expect(@bubble_datas).to be_true
    end

    it "日本語名をバブルチャート表示データへ付与できること" do
      d_hsh = metrics_day_type_jp_caption('all_day', @metrics_for_graph_merge)
      home_graph_data = concat_data_for_graph(@bubble_datas, d_hsh)

      expect(home_graph_data[:pageviews][:jp_caption]).to eq('PV数')
      expect(home_graph_data[:pageviews_per_session][:jp_caption]).to eq('平均PV数')
      expect(home_graph_data[:sessions][:jp_caption]).to eq('セッション')
      expect(home_graph_data[:avg_session_duration][:jp_caption]).to eq('平均滞在時間')
      expect(home_graph_data[:bounce_rate][:jp_caption]).to eq('直帰率')
      expect(home_graph_data[:percent_new_sessions][:jp_caption]).to eq('新規ユーザー')
      expect(home_graph_data[:users][:jp_caption]).to eq('ユーザー')
      expect(home_graph_data[:repeat_rate][:jp_caption]).to eq('リピーター')
    end
  end
end
