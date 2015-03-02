module Statistics

  class DayFactory

    attr_reader :data

    def initialize(days_data, komoku, day_type, cv_num)
      @days_data = days_data
      @komoku = komoku
      @day_type = day_type
      @cv_num = cv_num.to_s

      if @day_type == 'all_day'
        @data = Statistics::AllDay.new(@days_data, @komoku, @cv_num)
      elsif day_type == 'day_on'
        @data = Statistics::DayOn.new(@days_data, @komoku, @cv_num)
      elsif day_type == 'day_off'
        @data = Statistics::DayOff.new(@days_data, @komoku, @cv_num)
      end
    end
  end

end
