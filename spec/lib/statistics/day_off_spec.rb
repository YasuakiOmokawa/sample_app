require('rails_helper')

describe Statistics::DayOff do
  before(:all) do
    require 'pstore'
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ga_profile = garb[:ga_profile]
        @ast_data = garb[:ast_data]
      }
      @day_off = Statistics::DayOff.new(@ast_data, :pageviews, 1)
    end

    it "インスタンスが正常であること" do
      expect(@day_off).to be_true
    end

    it "インスタンス化したときの項目を取得できること" do
      expect(@day_off.komoku).to eq(:pageviews__day_off)
    end

    it "土日祝日の数を取得できること" do
      expect(@day_off.get_metrics.size).to eq(12)
    end
end
