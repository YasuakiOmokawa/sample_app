module UpdateTable

  def calc_percent_for_favorite_table(ssn, table, data_type)
    table.each do |k, v|
      table[k][data_type] = (table[k][data_type] / ssn * 100).round(1) if table[k][data_type] >0
    end
    table
  end

  # 共通ギャップ値テーブルのGAP値を計算
  def calc_gap_for_common(table)
    table.each do |k, v|
      g = table[k][:good].to_f
      b = table[k][:bad].to_f
      table[k][:gap] = b - g
    end
    return table
  end

  def calc_gap_for_graph(table, clm)
    begin
      shori = 'グラフ値テーブルのGAP値を計算'

      table.each do |k, v|
        date = k.to_s # きちんと変換してやんないとnilClass エラーになるので注意
        clm.each do |u, w|
          table[date][u][2] = table[date][u][1].to_f - table[date][u][0].to_f
        end
      end
      return table
    rescue => e
      puts "エラー： #{shori}"
      puts e.message
    end
  end

  # 秒を指定フォーマットへ変換
  # 時間の書式は、 hh:mm:ss
  # ロジック変更が発生したら、useJqplot.js tickFormatter() もチェックすること
  def chg_time(v)

    v_org = v
    v = v.to_i.abs

    h = (v / 36000 | 0).to_s + (v / 3600 % 10 | 0).to_s
    m = (v % 3600 / 600 | 0).to_s + (v % 3600 / 60 % 10 | 0).to_s
    s = (v % 60 / 10 | 0).to_s + (v % 60 % 10).to_s
    # str = h + ':' + m + ':' + s # 20140901 mm:ss 形式へ変更（分は3桁以上を許容）
    m = m.to_i + h.to_i * 60
    m = m.to_s
    if m.size < 2
      m = "0" + m
    end
    str = m + ':' + s
    # puts 'converted time is ' + s

    if v_org.to_i  < 0 then
      str = "-" + str
    end

    # puts "converted time is " + str
    str
  end

  def chg_percent(value)
    value.to_f.round(1).to_s + '%'
  end

  def format_value(format, value)
    return value if value == '-'
    case format
    when "time" then
      chg_time(value)
    when "percent" then
      chg_percent(value)
    when "number" then
      value.to_f.round(1).to_s
    end
  end

  def change_format_for_desire(table, format, value)
    table[:metrics_avg] = format_value(format, value[:metrics_avg])
    table[:metrics_stddev] = format_value(format, value[:metrics_stddev])
    table[:desire] = format_value(format, value[:desire])
    table
  end

  def change_format_for_graph_table(table, format, value)
    # binding.pry
    table[0] = format_value(format, value)
    table
  end


  # 人気ページテーブルのギャップ値を計算
  def calc_gap_for_favorite(tbl)
    tbl.each do |k, v|
      v[:gap] = (v[:bad].to_f - v[:good].to_f)
    end
    return tbl
  end

  def metrics_day_type_jp_caption(day_type, metricses)
    if day_type == 'day_on'
      d_hsh = add_metrics_day_on(metricses)
    # metricses.merge!(d_on_sh)
    elsif day_type == 'day_off'
      d_hsh = add_metrics_day_off(metricses)
    elsif day_type == 'all_day'
    # metricses.merge!(d_off_sh)
      d_hsh = metricses
    end
    d_hsh
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

  def concat_data_for_graph(datas, mets)
    mets.each do |k, v|
      datas[k][:jp_caption] = mets[k][:jp_caption]
      datas.delete(k) if datas[k].size == 1
    end
    datas
  end

  def delete_metrics(datas, m)
    [m, day_on_komoku(m), day_off_komoku(m)].each do |t|
      datas.delete(t)
    end
    datas
  end

  def create_common_skelton_table(col)
    Array(col).reduce(Hash.new{ |h,k| h[k] = {} }) do |acum, metrics|
      acum[metrics][:corr] = '-'
      acum[metrics][:corr_sign] = 'none'
      acum[metrics][:vari] = '-'
      acum[metrics][:metrics_stddev] = '-'
      acum[metrics][:metrics_avg] = '-'
      acum
    end
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

  def head_special(table, limit)
    res = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    cnt = 0

    table.sort_by { |a, b| [-(b[:corr].to_f) ] }.each do |k, v|
      res[k.to_s] = table[k]
      cnt += 1
      break if cnt >= limit
    end
    res
  end

  private

end
