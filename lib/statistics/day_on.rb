module Statistics

  class DayOn < AllDay

    def initialize(days_data, komoku, cv_num)
      @komoku = komoku
      @data = days_data.select {|item| item.day_type == 'day_on'}
      @cv_num = cv_num.to_s
    end

    def komoku
      (@komoku.to_s + '__day_on').to_sym
    end
  end
end
