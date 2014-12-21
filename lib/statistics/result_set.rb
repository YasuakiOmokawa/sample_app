module Statistics

  class ResultSet

    attr_reader :result

    def initialize(data)
      @result = Hash.new { |h, k| h[k] = {} }
      @data = data
    end

    def set_corr
      @result[@data.komoku][:corr] = @data.get_corr.round(1).abs
    end

    def set_corr_sign
      @result[@data.komoku][:corr_sign] = @data.get_corr_sign
    end

    def set_variation
      @result[@data.komoku][:vari] = @data.get_variation
    end

    def set_metrics_stddev
      @result[@data.komoku][:metrics_stddev] = @data.get_stddev
    end

    def set_metrics_avg
      @result[@data.komoku][:metrics_avg] = @data.get_avg
    end
  end
end
