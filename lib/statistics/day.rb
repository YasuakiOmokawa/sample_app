module Statistics

  class Day

    attr_reader :data

    def initialize(days_data)
      @data = days_data
    end

    def day_on
      @data.select {|k, v| v[:day_type] == 'day_on'}
    end

    def day_off
      @data.reject {|k, v| v[:day_type] == 'day_on'}
    end

    def get_cves(d)
      d.map {|k, v| v[:cv].to_f}
    end

    def count_cves(d)
      d.select {|k, v| v[:cv].to_f >= 1}.size
    end

    def uniq_day_type(d)
      d.map {|k, v| v[:day_type]}.uniq
    end

    def self.chk_not_a_number(target)
      if target.nan?
        0.0
      else
        target
      end
    end

    def self.check_number_sign(n)
      if n >= 0
        'plus'
      else
        'minus'
      end
    end
  end
end
