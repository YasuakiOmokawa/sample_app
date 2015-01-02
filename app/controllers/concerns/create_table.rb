module CreateTable

  def chk_monthly?(ym)
    if ym.size >= 2
      true
    else
      false
    end
  end

  def create_data_for_graph_display(hash, table, param)
    table.sort_by{ |a, b| b[:idx] }.each do |k, v|
      date =  k.to_i
      metrics = v[param][0] + v[param][1]
      day_type = v[param][3]
      hash[date] = [
        metrics,
        v[:cv].to_i,
        day_type
      ]
    end
    hash
  end

  def create_monthly_summary_data_for_graph_display(data, ym, format)
    tmp = Hash.new{ |h,k| h[k] = {} }
    ym.each do |t|
      tmp[t.to_i] = [
        set_data_for_format(select_metrics(data, t), format),
        set_data_for_format(select_cves(data, t), format)
      ]
    end
    tmp
  end

  def select_metrics(data, t)
    data.select{|k, v| /#{t}/ =~ k.to_s}.map{|k, v| v[0]}
  end

  def select_cves(data, t)
    data.select{|k, v| /#{t}/ =~ k.to_s}.map{|k, v| v[1]}
  end

  def set_data_for_format(data, format)
    case format
    when :pageviews, :sessions, :users
      data.sum.to_f.round(1)
    when :avg_session_duration, :bounce_rate, :percent_new_sessions, :repeat_rate, :pageviews_per_session
      data.avg.to_f.round(1)
    end
  end

  # ギャップ値なしテーブルスケルトン作成
  def create_skeleton(h, cv, cvr)
      h[:sessions] = 0
      h[:pageviews] = 0
      h[:bounce_rate] = 0
      h[(cv.to_sym)] = 0
      h[cvr.to_sym] = 0
  end

  # 共通ギャップ値テーブルスケルトンを作成
  def create_skeleton_gap_table(result_hash)
    [:good, :bad, :gap].each do |t|
      result_hash[:pageviews_per_session][t] = 0
      result_hash[:avg_session_duration][t] = 0
      result_hash[:percent_new_sessions][t] = 0
      result_hash[:repeat_rate][t] = 0
    end
    return result_hash
  end

  # バブル（散布図）チャート用算出データを作成
  def create_skeleton_bubble(a)
    rhsh = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    a.each do |t|
      [:good, :bad, :gap].each do |s|
        rhsh[t][s] = 0
      end
    end
    return rhsh
  end

  def create_skeleton_for_ref(data, hsh, from, to, clm)
    data.each do |z|
      tmp = Hash.new { |h,k| h[k] = {} }
      hsh[z.source.to_sym] = create_skeleton_for_graph(tmp, from, to, clm)
    end unless data.total_results == 0
    hsh
  end

  def create_skeleton_for_soc(data, hsh, from, to, clm)
    data.each do |z|
      tmp = Hash.new { |h,k| h[k] = {} }
      hsh[z.social_network.to_sym] = create_skeleton_for_graph(tmp, from, to, clm)
    end unless data.total_results == 0
    hsh
  end


  # グラフ値テーブルスケルトンを作成
  def create_skeleton_for_graph(hsh, from, to, clm)
    idx = 1
    (from..to).each do |t|
      dts = t.to_s.gsub( /-/, "" )
      d_type = chk_day(t)

      clm.each do |u, i|
        hsh[dts][:cv] = 0
        hsh[dts]["idx"] = idx
        hsh[dts][:day_type] = d_type
        hsh[dts][u] = set_array_on_date(d_type)
      end
      idx += 1
    end
    return hsh
  end

  # 土日祝日判定
    # wday 0 .. sun, 'day_sun'
    # wday 6 .. sat, 'day_sat'
    # 祝日 .. 'day_hol'
    # 平日 .. 'day_on'
  def chk_day(a)
    if a.wday == 0
      'day_sun'
    elsif a.wday == 6
      'day_sat'
    elsif HolidayJapan.check(a)
      'day_hol'
    else
      'day_on'
    end
  end

  def set_array_on_date(date_type)
    [0, 0, 0, date_type, 0]
  end

  # 曜日別の値を出すテーブルを作成
  # パーセンテージ、平均PV数、平均滞在時間、だったら平均値。それ以外は総数（にしないと値がへんになる）
  def create_table_by_days(table, data, item)
    cntr_on = cntr_off = 0
    [:day_on, :day_off].each do |t|
      [:good, :bad, :gap].each do |u|
        table[t][u] = 0
      end
    end
    data.each do |k, v|
      if v[item][3] == 'day_on' then
        cntr_on = cntr_on + 1
        table[:day_on][:good] += v[item][0].to_i
        table[:day_on][:bad] += v[item][1].to_i
        table[:day_on][:gap] += v[item][2].to_i
      else
        cntr_off = cntr_off + 1
        table[:day_off][:good] += v[item][0].to_i
        table[:day_off][:bad] += v[item][1].to_i
        table[:day_off][:gap] += v[item][2].to_i
      end
    end
    if item =~ /(rate|percent|avg_|_per_)/ then
      puts "calc average because of item is #{item}"
      {:day_on => cntr_on , :day_off => cntr_off }.each do |k, v|
        [:good, :bad, :gap].each do |u|
          if v == 0 then
            v = 1
          end
          avg = table[k][u].to_i / v
          table[k][u] = avg
          puts "calc avg ok! cntr_info is #{k}, cntr_value is #{v}, avg value is #{avg}"
        end
      end
    end
    return table
  end

  # 人気ページテーブルを生成
  def create_skeleton_favorite_table(data, table)
    cnt = 0
    data.each do |k|
      cnt += 1
      key = k.page_title + ";;" + k.page_path
      table[key][:index] = cnt
      [:good, :bad, :gap].each do |s|
        table[key][s] = 0
      end
    end
    table
  end

  # ランディングページテーブルを作成
  def create_skeleton_landing_table(data, table)
    cnt = 0
    data.each do |k|
      cnt += 1
      key = k.page_title + ";;" + k.landing_page_path
      table[key][:index] = cnt
      [:good, :bad, :gap].each do |s|
        table[key][s] = 0
      end
    end
    table
  end

  # referral, social, campaign 個別テーブルを生成
  def create_skeleton_for_rsc(data, key)
    result_hash = Hash.new{ |h, k| h[k] = {} }
    if data.total_results != 0 then
      data.each do|t|
        [:good, :bad, :gap].each do |s|
          result_hash[t.send(key)][s] = 0
        end
      end
    end
    return result_hash
  end

end
