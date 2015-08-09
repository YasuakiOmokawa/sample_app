module UpdateTable

  def metrics_day_type_jp_caption(day_type, metricses)
    if day_type == 'day_on'
      d_hsh = add_metrics_day_on(metricses)
    elsif day_type == 'day_off'
      d_hsh = add_metrics_day_off(metricses)
    elsif day_type == 'all_day'
      d_hsh = metricses
    end
    d_hsh
  end

  def concat_data_for_graph(datas, mets)
    mets.each do |k, v|
      datas[k][:jp_caption] = mets[k][:jp_caption]
      datas.delete(k) if datas[k].size == 1
    end
    datas
  end

  def generate_graph_data(tbl, col, type)
    r_hsh = Hash.new{ |h,k| h[k] = {} }

    # 項目別
    Array(col).each do |komoku, jp|

      df = Statistics::DayFactory.new(tbl, komoku, type, @cv_num).data
      metrics_and_cv = Statistics::MetricsAndCV.new(df.get_metrics.zip(df.get_cves)).create

      # 外れ値検出ロジック
      metrics_and_cv = detect_outlier_with_iqr(df, metrics_and_cv)

      metrics = get_detected_metrics(metrics_and_cv)
      cv = get_detected_cves(metrics_and_cv)

      tmp = Hash.new{ |h,k| h[k] = {} }

      tmp[df.komoku][:corr] = metrics_and_cv.blank? ? '-' : chk_not_a_number(metrics.corrcoef(cv)).round(1).abs
      tmp[df.komoku][:corr_sign] = metrics_and_cv.blank? ? 'none' : check_number_sign(chk_not_a_number(metrics.corrcoef(cv)).round(1))
      tmp[df.komoku][:vari] = metrics_and_cv.blank? ? '-' : chk_not_a_number( (metrics.stddev / metrics.avg).round(1) )
      tmp[df.komoku][:metrics_stddev] = metrics_and_cv.blank? ? '-' : metrics.stddev.round(1)
      tmp[df.komoku][:metrics_avg] = metrics_and_cv.blank? ? '-' : metrics.avg.round(1)

      r_hsh.merge!(tmp)
    end
    r_hsh
  rescue
    puts $!
    puts $@
  end

  def calc_desire_datas(tbl)
    tbl.each do |k, v|
      if tbl[k][:corr_sign] == 'plus'
        tbl[k][:desire] = (tbl[k][:metrics_avg] + tbl[k][:metrics_stddev]).round(1)
      elsif tbl[k][:corr_sign] == 'minus'
        tbl[k][:desire] = (tbl[k][:metrics_avg] - tbl[k][:metrics_stddev]).round(1)
      else
        tbl[k][:desire] = '-'
      end
    end
    tbl
  end

  def replace_cv_with_custom(custom, cv, ident)

    cv.each do |item|
      matcher = set_date_format(
        create_matcher(item[:date])).to_s
      matched = custom.upload_file.
        find {|t| set_date_format(t[0]).to_s.match(
          /#{matcher}/)}
      item[ident.to_sym] = matched[1] unless matched.nil?
    end unless custom.nil?
  end

  private

    def create_matcher(o)
      [
        o[0..3].to_i.to_s,
        o[4..5].to_i.to_s,
        o[6..7].to_i.to_s
      ].join('/') unless o.nil?
    end

    def add_metrics_day_on(mets)
      hsh = {}
      mets.each do |k, v|
        key = day_on_komoku(k)
        value = v[:jp_caption].to_s + ';;' + '平日'
        hsh[key] = {jp_caption: value}
      end
      hsh
    end

    def add_metrics_day_off(mets)
      hsh = {}
      mets.each do |k, v|
        key = day_off_komoku(k)
        value = v[:jp_caption].to_s + ';;' + '土日祝'
        hsh[key] = {jp_caption: value}
      end
      hsh
    end

    def day_on_komoku(komoku)
      (komoku.to_s + '__day_on').to_sym
    end

    def day_off_komoku(komoku)
      (komoku.to_s + '__day_off').to_sym
    end
end
