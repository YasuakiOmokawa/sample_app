module Statistics

  class DayFactory

    attr_reader :data

    def initialize(days_data, komoku, day_type)
      @days_data = days_data
      @komoku = komoku
      @day_type = day_type

      if @day_type == 'all_day'
        @data = Statistics::AllDay.new(@days_data, @komoku)
      elsif day_type == 'day_on'
        @data = Statistics::DayOn.new(@days_data, @komoku)
      elsif day_type == 'day_off'
        @data = Statistics::DayOff.new(@days_data, @komoku)
      end
    end
  end

end
