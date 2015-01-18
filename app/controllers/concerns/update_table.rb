module UpdateTable

  def calc_desire_datas(tbl)
    tbl.each do |k, v|
      if tbl[k][:corr_sign] == 'plus'
       tbl[k][:desire] = (tbl[k][:metrics_avg] + tbl[k][:metrics_stddev]).round(1)
     else
       tbl[k][:desire] = (tbl[k][:metrics_avg] - tbl[k][:metrics_stddev]).round(1)
      end
    end
    tbl
  end

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

  def chk_not_a_number(target)
    if target.nan?
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

  def generate_graph_data(tbl, col, type)
    r_hsh = Hash.new{ |h,k| h[k] = {} }

    # 項目別
    col.each do |komoku, jp|

      df = Statistics::DayFactory.new(tbl, komoku, type).data
      rs = Statistics::ResultSet.new(df)

      rs.set_corr
      rs.set_corr_sign
      rs.set_variation
      rs.set_metrics_stddev
      rs.set_metrics_avg

      r_hsh.merge!(rs.result)
    end
    r_hsh
  rescue
    puts $!
    puts $@
  end

  def head_special(table, limit)
    res = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    cnt = 0

    table.sort_by { |a, b| [-(b[:corr]) ] }.each do |k, v|
      res[k.to_s] = table[k]
      cnt += 1
      break if cnt >= limit
    end
    res
  end

  # def get_metrics(tbl, komoku)
  #   tbl.map {|k, v| v[komoku][0].to_f + v[komoku][1].to_f}
  # end

  # def metrics_day_on(tbl, komoku)
  #   tbl.select {|k, v| v[komoku][3] == 'day_on'}
  # end

  # def metrics_day_off(tbl, komoku)
  #   tbl.reject {|k, v| v[komoku][3] == 'day_on'}
  # end

  # def get_cves(tbl)
  #   tbl.map {|k, v| v[:cv].to_f}
  # end

  # def cv_day_on(tbl)
  #   tbl.select {|k, v| v[:pageviews][3] == 'day_on'}
  # end

  # def cv_day_off(tbl)
  #   tbl.reject {|k, v| v[:pageviews][3] == 'day_on'}
  # end

  # def add_corr(r_hsh, komoku, corr)
  #   r_hsh[komoku][:corr] = corr
  # end

  # def add_corr_sign(r_hsh, komoku, c)
  #   r_hsh[komoku][:corr_sign] = c
  # end

  # def add_variation(r_hsh, komoku, vari)
  #   r_hsh[komoku][:vari] = vari
  # end

  # def add_metrics_stddev(r_hsh, komoku, v)
  #   r_hsh[komoku][:metrics_stddev] = v
  # end

  # def add_metrics_avg(r_hsh, komoku, v)
  #   r_hsh[komoku][:metrics_avg] = v
  # end

  # def collect_bubble_metricses(tbl, komoku)
  #   {
  #     all_day_metrics: get_metrics(tbl, komoku),
  #     day_on_metrics: get_metrics(metrics_day_on(tbl, komoku), komoku),
  #     day_off_metrics: get_metrics(metrics_day_off(tbl, komoku), komoku),
  #   }
  # end

  # def collect_bubble_cves(tbl, komoku)
  #   {
  #     all_day_cvs: get_cves(tbl),
  #     day_on_cvs: get_cves(cv_day_on(tbl)),
  #     day_off_cvs: get_cves(cv_day_off(tbl)),
  #   }
  # end

  # def calc_corr(met, cv)
  #   chk_not_a_number(met.corrcoef(cv))
  # end

  # def calc_corrs(h, i)
  #   all_day_corr = calc_corr(h[:all_day_metrics], i[:all_day_cvs])
  #   day_on_corr = calc_corr(h[:day_on_metrics], i[:day_on_cvs])
  #   day_off_corr = calc_corr(h[:day_off_metrics], i[:day_off_cvs])

  #   {
  #     all_day_corr: all_day_corr.round(1).abs,
  #     day_on_corr: day_on_corr.round(1).abs,
  #     day_off_corr: day_off_corr.round(1).abs,
  #     all_day_corr_sign: check_number_sign(all_day_corr),
  #     day_on_corr_sign: check_number_sign(day_on_corr),
  #     day_off_corr_sign: check_number_sign(day_off_corr),
  #   }
  # end

  # def add_results(j, k, r_hsh, komoku)
  #   komoku_day_on = day_on_komoku(komoku)
  #   komoku_day_off = day_off_komoku(komoku)

  #   add_corr(r_hsh, komoku, j[:all_day_corr])
  #   add_corr(r_hsh, komoku_day_on, j[:day_on_corr])
  #   add_corr(r_hsh, komoku_day_off, j[:day_off_corr])

  #   add_corr_sign(r_hsh, komoku, j[:all_day_corr_sign])
  #   add_corr_sign(r_hsh, komoku_day_on, j[:day_on_corr_sign])
  #   add_corr_sign(r_hsh, komoku_day_off, j[:day_off_corr_sign])

  #   add_variation(r_hsh, komoku, k[:all_day_variation])
  #   add_variation(r_hsh, komoku_day_on, k[:day_on_variation])
  #   add_variation(r_hsh, komoku_day_off, k[:day_off_variation])

  #   add_metrics_stddev(r_hsh, komoku, k[:all_day_metrics_stddev])
  #   add_metrics_stddev(r_hsh, komoku_day_on, k[:day_on_metrics_stddev])
  #   add_metrics_stddev(r_hsh, komoku_day_off, k[:day_off_metrics_stddev])

  #   add_metrics_avg(r_hsh, komoku, k[:all_day_metrics_avg])
  #   add_metrics_avg(r_hsh, komoku_day_on, k[:day_on_metrics_avg])
  #   add_metrics_avg(r_hsh, komoku_day_off, k[:day_off_metrics_avg])
  # end

  # def calc_variations(h)
  #   {
  #     all_day_variation: (h[:all_day_metrics].stddev.round(1) / h[:all_day_metrics].avg.round(1)).round(1),
  #     day_on_variation: (h[:day_on_metrics].stddev.round(1) / h[:day_on_metrics].avg.round(1)).round(1),
  #     day_off_variation: (h[:day_off_metrics].stddev.round(1) / h[:day_off_metrics].avg.round(1)).round(1),
  #     all_day_metrics_stddev: h[:all_day_metrics].stddev.round(1),
  #     day_on_metrics_stddev: h[:day_on_metrics].stddev.round(1),
  #     day_off_metrics_stddev: h[:day_off_metrics].stddev.round(1),
  #     all_day_metrics_avg: h[:all_day_metrics].avg.round(1),
  #     day_on_metrics_avg: h[:day_on_metrics].avg.round(1),
  #     day_off_metrics_avg: h[:day_off_metrics].avg.round(1),
  #   }
  # end

  # def generate_bubble_data(tbl, col)
  #   r_hsh = Hash.new{ |h,k| h[k] = {} }

  #   # 項目別
  #   col.each do |komoku, jp|

  #     # 判別対象データを作成
  #     h = collect_bubble_metricses(tbl, komoku)
  #     i = collect_bubble_cves(tbl, komoku)

  #     # 相関係数の算出
  #     j = calc_corrs(h, i)

  #     # 変動係数の算出
  #     k = calc_variations(h)

  #     # 各数値を返却
  #     add_results(j, k, r_hsh, komoku)

  #   end
  #   r_hsh
  # rescue
  #   puts $!
  #   puts $@
  # end

  # def set_cr_to_dy_bf_cr_of_calc_corr(cr, bf)
  #   bf.dy = cr.dy
  #   bf.dt_dy = cr.dt_dy
  #   bf.gp_dy = cr.gp_dy
  #   bf.cv_dy = cr.cv_dy
  # end

  # def calc_sabun_of_calc_corr(cr, bf)
  #   dt_sbn = cr.dt_dy - bf.dt_dy
  #   gp_sbn = cr.gp_dy - bf.gp_dy
  #   cv_sbn = cr.cv_dy - bf.cv_dy
  #   puts "項目の差分 is #{dt_sbn}, gap値の差分 is #{gp_sbn}, and CVの差分 is #{cv_sbn}"
  #   puts "当日の項目値 is #{cr.dt_dy}, 当日のCV is #{cr.cv_dy}, 当日のGAP値 is #{cr.gp_dy}"
  #   puts " "
  #   return dt_sbn, gp_sbn, cv_sbn
  # end


  # # 相関ポイント集計
  # def count_corr_point(t, pt, r_hsh)
  #   r_hsh[t][:corr] = pt + r_hsh[t][:corr].to_i
  # end

  # def counts_day_of_the_week(d_hsh, ky, gp_dy, pt, r_hsh)
  #   d_hsh[ky] = 1 + d_hsh[ky].to_i # 曜日別の項目数をカウント
  #   r_hsh[ky][:gap] = gp_dy + r_hsh[ky][:gap].to_i # 曜日別のGAP値を集計
  #   r_hsh[ky][:corr] = pt + r_hsh[ky][:corr].to_i # 曜日別の相関ポイントを集計
  # end

  # # 相関ポイントの計算
  # def calc_soukan(mtrcs, gp, cv, cv_dy, gp_dy, dt, dt_dy)

  #   shori = '相関ポイントの計算'

  #   case mtrcs

  #   # GAP値のあるものについて、相関を計算
  #   # 対象: 平均PV数、平均滞在時間、新規訪問率、再訪問率
  #   when :pageviews_per_session, :avg_session_duration, :percent_new_sessions, :repeat_rate
  #     if ( cv < 0 && gp > 0.0 ) || ( cv > 0 && gp < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( gp == 0 && gp_dy > 0.0 ))
  #       p "#{mtrcs} get 1pt"
  #       pt = 1
  #     else
  #       p "#{mtrcs} get 0pt"
  #       pt = 0
  #     end
  #   # 直帰率の場合
  #   when :bounce_rate
  #     if ( cv < 0 && dt > 0.0 ) || ( cv > 0 && dt < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( dt == 0 && dt_dy > 0.0 ))
  #       p "#{mtrcs} get 1pt"
  #       pt = 1
  #     else
  #       p "#{mtrcs} get 0pt"
  #       pt = 0
  #     end
  #   # その他、GAP値なしデータについて、相関を計算
  #   else
  #     if ( cv > 0 && dt > 0.0 ) || ( cv < 0 && dt < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( dt == 0 && dt_dy > 0.0 ))
  #       p "#{mtrcs} get 1pt"
  #       pt = 1
  #     else
  #       p "#{mtrcs} get 0pt"
  #       pt = 0
  #     end
  #   end
  #   pt
  #   rescue => e
  #     puts "エラー： #{shori}"
  #     puts e.message
  # end

  # # ページ相関の種類によってプロパティ値を変更
  # def chk_flg(cr, v, flg, t)

  #   shori = 'ページ相関の種類によってプロパティ値を変更'
  #   # binding.pry # ブレークポイントスイッチ
  #   case flg
  #   when 'fvt' then # 人気ページ相関の場合
  #     cr.cv_dy = v[t][4].to_i
  #   else
  #     # binding.pry # ブレークポイントスイッチ
  #     cr.cv_dy = v[:cv].to_i
  #     # cr.cvr_dy = v[cvr][2].to_f
  #   end
  #   rescue => e
  #     puts "エラー： #{shori}"
  #     puts e.message
  # end

  # # 曜日種類別にGAPの算出
  # def calc_gap_per_day(d_hsh, r_hsh)

  #   # d_hsh の中身 k.. 項目と曜日の種別 v.. 曜日の数

  #   d_hsh.each do |c, d|

  #     # binding.pry # ブレークポイントスイッチ
  #     if c =~ /(rate|percent|avg_|_per_)/

  #       # puts "calc average because of item is #{c}"

  #       d_hsh[c] = 1 if d_hsh[c] == 0

  #       avg = r_hsh[c][:gap] / d_hsh[c]

  #       r_hsh[c][:gap] = avg

  #       puts "calc gap_avg ok! key is #{c}, value is #{avg}"
  #       # binding.pry
  #     end
  #   end
  #   r_hsh
  # end

  # # GAP値のパーセンテージを値へ変換
  # def calc_pct_to_num(tbl)
  #   max = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.max_by {|k,v| v[:gap] }[1][:gap]
  #   min = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.min_by {|k,v| v[:gap] }[1][:gap]
  #   basis = ((max - min) / 100)
  #   puts " max is #{max}, min is #{min}, base value is #{basis}"
  #   tbl.select{|k,v| k =~ /(rate|percent|fav_page)/}.each do |k,v|
  #     value = (v[:gap] * basis).to_i
  #     v[:gap] = value
  #     puts "convert pct to num success! key is #{k}, value is #{value}"
  #   end
  #   return tbl
  # end

  # # GAP値の数値をパーセンテージへ変換
  # def calc_num_to_pct(tbl)

  #   max = tbl.reject{|k,v| k =~ /(rate|percent)/}.max_by {|k,v| v[:gap] }[1][:gap]
  #   min = tbl.reject{|k,v| k =~ /(rate|percent)/}.min_by {|k,v| v[:gap] }[1][:gap]

  #   # 変換の基準となる値を算出
  #   basis = ((max - min) / 100)
  #   puts " max is #{max}, min is #{min}, base value is #{basis}"

  #   tbl.reject{|k,v| k =~ /(rate|percent)/}.each do |k,v|
  #     if v[:gap] == max and v[:gap] > 0 then
  #       value = 100
  #     elsif v[:gap] == min and v[:gap] == 0 then
  #       value = 0
  #     else
  #       value = (v[:gap] / basis).to_i
  #     end

  #     puts "Convert num to pct success! key is #{k}, row value is #{v[:gap]}, converted value is #{value}"

  #     v[:gap] = value
  #   end
  #   return tbl
  # end

  # # pageviews, sessions は gap の箇所に項目値を入れる（グラフ表示の為）
  # def change_gap_to_komoku(skel)
  #   # skel.select{|k, v| k =~ /(^pageviews$|^pageviews |^sessions $)/}
  #   skel.select{|k, v| k =~ /(^pageviews$|^sessions$|^bounce_rate$)/}.each do |k, v|
  #     v[:gap] = v[:good].to_i + v[:bad].to_i
  #   end
  # end

  # def change_gap_to_abs(skel)
  #   skel.each do |k, v|
  #     v[:gap] = v[:gap].abs
  #   end
  # end

  # def change_gap_to_minus(skel)
  #   skel.each do |k, v|
  #     v[:gap] = - v[:gap]
  #   end
  # end

  # def substr_fav(dt, rank)
  #   begin
  #     shori = '人気ページランク抽出'
  #     r_hsh = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
  #     dt.each do |k, v|
  #       r_hsh[k] = v if rank.include?(k)
  #     end
  #     return r_hsh
  #   rescue => e
  #     puts "エラー：#{shori}"
  #     puts e.message
  #   end
  # end

  # def seikei_rank(rank)
  #   arr = []
  #   rank.each do |k, v|
  #     if v[0] == 'その他' then
  #       key = v[0]
  #     else
  #       key = v[0] + ';;' + v[1]
  #     end
  #     arr.push(key)
  #   end
  #   return arr
  # end

  # def pickup_gap_per_day(corr)
  #   gap_day = Hash.new{ |h, k| h[k] = {} }

  #   corr.select{|k, v| k =~ /(day_)/}.each do |k, v|

  #     page, day_type = k.split(' ')

  #     select_day_type_for_pickup_gap_per_day(day_type, gap_day, page, v)

  #   end
  #   gap_day
  #   rescue => e
  #     puts e.message
  # end

  # def select_day_type_for_pickup_gap_per_day(day_type, gap_day, page, v)

  #   if  day_type =~ /(day_on)/
  #     gap_day["#{page} day_on"][:gap] = v[:gap]
  #   else
  #     gap_day["#{page} day_off"][:gap] = v[:gap]
  #   end
  # rescue
  #   puts $!
  #   puts $@
  # end

  private

    # def set_data_of_calc_corr(v, cr, komoku, date)
    #   cr.dt_dy = v[komoku][0].to_f + v[komoku][1].to_f # 項目値(理想値＋現実値)
    #   cr.gp_dy = v[komoku][2].to_f # GAP
    #   cr.dy = v[komoku][3] # 曜日種別
    #   # cr.cvr_dy = 1
    #   cr.date = date
    # end

    # def hoge
    #   puts 'hoge'
    #   binding.pry
    #   puts 'huga'
    # end



end
