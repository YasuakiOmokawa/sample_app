module Statistics

  class DayOff < AllDay

    def initialize(days_data, komoku, cv_num)
      @komoku = komoku
      @data = days_data.reject {|item| item.day_type == 'day_on'}
      @cv_num = cv_num.to_s
    end

    def komoku
      (@komoku.to_s + '__day_off').to_sym
    end
  end
end
