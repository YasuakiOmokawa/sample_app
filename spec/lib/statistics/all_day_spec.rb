require('rails_helper')

describe Statistics::AllDay do

  before(:all) do
    require 'pstore'
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ga_profile = garb[:ga_profile]
        @ast_data = garb[:ast_data]
      }
      @all_day = Statistics::AllDay.new(@ast_data, :pageviews, 1)
    end

    it "インスタンスが正常であること" do
      expect(@all_day).to be_true
    end

    it "cvが正常に取得できること" do
      expect(@all_day.get_cves.size).to eq(31)
    end

    it "指標値が正常に取得できること" do
      expect(@all_day.get_metrics.size).to eq(31)
    end

    it "相関が正常に取得できること" do
      expect(@all_day.get_corr).to eq(0.14143331350729565)
    end

    it "NaNチェックが正常に動作すること" do
      expect(@all_day.chk_not_a_number([0].corrcoef([0]) ) ).to eq(0.0)
      expect(@all_day.chk_not_a_number( (1.0 / 0.0).round(1)) ).to eq(0.0)
      expect(@all_day.chk_not_a_number(1.0)).to eq(1.0)
    end

    it "相関の正負を取得できること" do
      expect(@all_day.get_corr_sign).to eq('plus')
    end

    it "数値の正負を取得できること" do
      expect(@all_day.check_number_sign(0)).to eq('plus')
      expect(@all_day.check_number_sign(-1)).to eq('minus')
    end

    it "インスタンス化したときの項目を取得できること" do
      expect(@all_day.komoku).to eq(:pageviews)
    end

    it "指標の標準偏差を取得できること" do
      expect(@all_day.get_stddev).to eq(76.8)
    end

    it "指標の平均値を取得できること" do
      expect(@all_day.get_avg).to eq(360.3)
    end

    it "指標の変動係数を取得できること" do
      expect(@all_day.get_variation).to eq(0.2)
    end
end
