require 'spec_helper'

describe Statistics::DayFactory do
  before(:all) do
    require 'pstore'
      out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
      db = PStore.new(out_file_path)
      db.transaction{ |garb|
        @ga_profile = garb[:ga_profile]
        @ast_data = garb[:ast_data]
      }
    end

    it "全日インスタンスが正常であること" do
      @all_day = Statistics::DayFactory.new(@ast_data, :pageviews, 'all_day', 1).data
      expect(@all_day.komoku).to  eq(:pageviews)
    end

    it "平日インスタンスが正常であること" do
      @day_on = Statistics::DayFactory.new(@ast_data, :pageviews, 'day_on', 1).data
      expect(@day_on.komoku).to eq(:pageviews__day_on)
    end

    it "土日祝日インスタンスが正常であること" do
      @day_off = Statistics::DayFactory.new(@ast_data, :pageviews, 'day_off', 1).data
      expect(@day_off.komoku).to eq(:pageviews__day_off)
    end
end
