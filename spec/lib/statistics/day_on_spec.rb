require('rails_helper')

describe Statistics::DayOn do
  before(:all) do
    require 'pstore'
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ga_profile = garb[:ga_profile]
        @ast_data = garb[:ast_data]
      }
      @day_on = Statistics::DayOn.new(@ast_data, :pageviews, 1)
    end

    it "インスタンスが正常であること" do
      expect(@day_on).to be_truthy
    end

    it "インスタンス化したときの項目を取得できること" do
      expect(@day_on.komoku).to eq(:pageviews__day_on)
    end

    it "平日の数を取得できること" do
      expect(@day_on.get_metrics.size).to eq(19)
    end
end
