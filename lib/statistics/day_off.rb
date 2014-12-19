module Statistics

  class DayOff < AllDay

    def initialize(days_data, komoku)
      @komoku = komoku
      @data = days_data.reject {|k, v| v[@komoku][3] == 'day_on'}
    end

    def komoku
      (@komoku.to_s + '__day_off').to_sym
    end
  end
end
