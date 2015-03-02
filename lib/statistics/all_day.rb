module Statistics

  class AllDay

    def initialize(days_data, komoku, cv_num)
      @komoku = komoku
      @data = days_data
      @cv_num = cv_num.to_s
    end

    def get_metrics
      @data.map {|item| item.send(@komoku).to_f}
    end

    def get_cves
      cv_txt = "goal#{@cv_num}_completions"
      @data.map { |item| item.send(cv_txt.to_sym).to_f }
    end

    def get_corr
      chk_not_a_number( get_metrics.corrcoef(get_cves) )
    end

    def get_corr_sign
      check_number_sign(get_corr)
    end

    def komoku
      @komoku
    end

    def get_stddev
      get_metrics.stddev.round(1)
    end

    def get_avg
      get_metrics.avg.round(1)
    end

    def get_variation
      chk_not_a_number( (get_stddev / get_avg).round(1) )
    end

    def chk_not_a_number(target)
      if (target.nan? or target.infinite?)
        0.0
      else
        target
      end
    end

    def check_number_sign(n)
      if n >= 0
        'plus'
      else
        'minus'
      end
    end
  end
end
