module Statistics

  class DayOn < AllDay

    def initialize(days_data, komoku)
      @komoku = komoku
      @data = days_data.select {|k, v| v[@komoku][3] == 'day_on'}
    end

    def komoku
      (@komoku.to_s + '__day_on').to_sym
    end
  end
end
