require 'spec_helper'

require 'holiday_japan'
require 'securerandom'
require "retryable"
require 'user_func'
require 'create_table'
require 'insert_table'
require 'update_table'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

describe UsersController do

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

  describe 'ホーム画面分析' do
    before do
      json_file_path =  Rails.root.join('spec', 'fixtures', 'table_for_graph.json').to_s
      json_data = open(json_file_path) do |io|
        JSON.load(io)
      end
      @table_for_graph = JSON.parse(json_data)
    end
    let(:df) { Statistics::DayFactory.new(@table_for_graph, "percent_new_sessions", 'all_day').data}
    let(:iqr) {IQR.new(df).create}

    it "31日分のデータがあること" do
      expect(@table_for_graph.size).to eq(31)
    end

    it "全日データのインスタンスが作成されていること" do
      expect(df.komoku).to eq("percent_new_sessions")
    end
  end

  describe "UserFunc" do
    before do
      require 'pstore'
        out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
        db = PStore.new(out_file_path)
        db.transaction{|garb|
          @ga_profile = garb[:ga_profile]
          @ast_data = garb[:ast_data]
      }
    end

    describe "validate_cv" do

      it "validate対象データが呼ばれること" do
        expect(@ast_data[0].date).to eq('20141101')
      end

      
    end
  end
end
