module UpdateTable

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

    logger.info("converted time is " + str)
    return str
  end

  # グラフ値テーブルのフォーマットを変更
  def change_format(table, item, format)
    table.each do |k, v|
      (0..2).each do |t|
        value = v[item][t]
        case format
        when "time" then
          str = chg_time(value)
        when "percent" then
          str = value.to_f.round(1).to_s + '%'
        when "number" then
          str = value.to_f.round(1).to_s
        end
        v[item][t] = str
      end
    end
    return table
  end

  # 人気ページテーブルのギャップ値を計算
  def calc_gap_for_favorite(tbl)
    tbl.each do |k, v|
      v[:gap] = (v[:bad].to_f - v[:good].to_f)
    end
    return tbl
  end

  # バブル（散布図）チャートのために相関を出す
  def calc_corr(tbl, col, cvr, flg = 'none')
    r_hsh = Hash.new{ |h,k| h[k] = {} }
    per_day_nums = {} # 曜日種別の日数を保持
    cr = Corr.new # 相関算出用に当日の値を格納

    # 項目別
    col.each do |komoku, i|

      dy_bf_cr = DyBfCorr.new # 相関算出用に前日の値を格納

      # 日付別
      tbl.sort_by{|a, b| (b['idx']) }.each do |date, per_date_value|

        set_data_of_calc_corr(per_date_value, cr, komoku, date)
        # binding.pry # ブレークポイントスイッチ

        # ページ相関の種類によってプロパティ値を変更
        chk_flg(cr, per_date_value, flg, komoku)

        # 前日と当日のデータが揃っていれば相関計算を開始
        unless dy_bf_cr.gp_dy.nil?
          # binding.pry # ブレークポイントスイッチ

          puts "差分を計算します。 日付：　#{cr.date} マイナス #{dy_bf_cr.date}  項目： #{komoku}"
          dt_sbn, gp_sbn, cv_sbn = calc_sabun_of_calc_corr(cr, dy_bf_cr)

          # binding.pry # ブレークポイントスイッチ
          # 相関ポイントの計算
          pt = calc_soukan(komoku, gp_sbn, cv_sbn, cr.cv_dy, cr.gp_dy, dt_sbn, cr.dt_dy)
          # binding.pry # ブレークポイントスイッチ

          unless flg == 'fvt'
            day_of_the_week_key = komoku.to_s + ' ' + cr.dy.to_s # 曜日別の項目数を格納するキー
            counts_day_of_the_week(per_day_nums, day_of_the_week_key, cr.gp_dy, pt, r_hsh)
          end

          # 相関ポイント集計
          count_corr_point(komoku, pt, r_hsh)
        end
        # binding.pickup_gap_per_day
        dy_bf_cr.date = date
        set_cr_to_dy_bf_cr_of_calc_corr(cr, dy_bf_cr)
      end
      # binding.pry # ブレークポイントスイッチ
    end

    # 曜日別GAPの算出
    calc_gap_per_day(per_day_nums, r_hsh)

    r_hsh
  rescue
    puts $!
    puts $@
  end

  def set_cr_to_dy_bf_cr_of_calc_corr(cr, bf)
    bf.dy = cr.dy
    bf.dt_dy = cr.dt_dy
    bf.gp_dy = cr.gp_dy
    bf.cv_dy = cr.cv_dy
  end

  def calc_sabun_of_calc_corr(cr, bf)
    dt_sbn = cr.dt_dy - bf.dt_dy
    gp_sbn = cr.gp_dy - bf.gp_dy
    cv_sbn = cr.cv_dy - bf.cv_dy
    puts "項目の差分 is #{dt_sbn}, gap値の差分 is #{gp_sbn}, and CVの差分 is #{cv_sbn}"
    puts "当日の項目値 is #{cr.dt_dy}, 当日のCV is #{cr.cv_dy}, 当日のGAP値 is #{cr.gp_dy}"
    puts " "
    return dt_sbn, gp_sbn, cv_sbn
  end


  # 相関ポイント集計
  def count_corr_point(t, pt, r_hsh)
    r_hsh[t][:corr] = pt + r_hsh[t][:corr].to_i
  end

  def counts_day_of_the_week(d_hsh, ky, gp_dy, pt, r_hsh)
    d_hsh[ky] = 1 + d_hsh[ky].to_i # 曜日別の項目数をカウント
    r_hsh[ky][:gap] = gp_dy + r_hsh[ky][:gap].to_i # 曜日別のGAP値を集計
    r_hsh[ky][:corr] = pt + r_hsh[ky][:corr].to_i # 曜日別の相関ポイントを集計
  end

  # 相関ポイントの計算
  def calc_soukan(mtrcs, gp, cv, cv_dy, gp_dy, dt, dt_dy)

    shori = '相関ポイントの計算'

    case mtrcs

    # GAP値のあるものについて、相関を計算
    # 対象: 平均PV数、平均滞在時間、新規訪問率、再訪問率
    when :pageviews_per_session, :avg_session_duration, :percent_new_sessions, :repeat_rate
      if ( cv < 0 && gp > 0.0 ) || ( cv > 0 && gp < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( gp == 0 && gp_dy > 0.0 ))
        p "#{mtrcs} get 1pt"
        pt = 1
      else
        p "#{mtrcs} get 0pt"
        pt = 0
      end
    # 直帰率の場合
    when :bounce_rate
      if ( cv < 0 && dt > 0.0 ) || ( cv > 0 && dt < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( dt == 0 && dt_dy > 0.0 ))
        p "#{mtrcs} get 1pt"
        pt = 1
      else
        p "#{mtrcs} get 0pt"
        pt = 0
      end
    # その他、GAP値なしデータについて、相関を計算
    else
      if ( cv > 0 && dt > 0.0 ) || ( cv < 0 && dt < 0.0) || (( cv == 0 && cv_dy >= 1 ) && ( dt == 0 && dt_dy > 0.0 ))
        p "#{mtrcs} get 1pt"
        pt = 1
      else
        p "#{mtrcs} get 0pt"
        pt = 0
      end
    end
    pt
    rescue => e
      puts "エラー： #{shori}"
      puts e.message
  end

  # ページ相関の種類によってプロパティ値を変更
  def chk_flg(cr, v, flg, t)

    shori = 'ページ相関の種類によってプロパティ値を変更'
    # binding.pry # ブレークポイントスイッチ
    case flg
    when 'fvt' then # 人気ページ相関の場合
      cr.cv_dy = v[t][4].to_i
    else
      # binding.pry # ブレークポイントスイッチ
      cr.cv_dy = v[:cv].to_i
      # cr.cvr_dy = v[cvr][2].to_f
    end
    rescue => e
      puts "エラー： #{shori}"
      puts e.message
  end

  # 曜日種類別にGAPの算出
  def calc_gap_per_day(d_hsh, r_hsh)

    # d_hsh の中身 k.. 項目と曜日の種別 v.. 曜日の数

    d_hsh.each do |c, d|

      # binding.pry # ブレークポイントスイッチ
      if c =~ /(rate|percent|avg_|_per_)/

        # puts "calc average because of item is #{c}"

        d_hsh[c] = 1 if d_hsh[c] == 0

        avg = r_hsh[c][:gap] / d_hsh[c]

        r_hsh[c][:gap] = avg

        puts "calc gap_avg ok! key is #{c}, value is #{avg}"
        # binding.pry
      end
    end
    r_hsh
  end

  # GAP値のパーセンテージを値へ変換
  def calc_pct_to_num(tbl)
    max = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.max_by {|k,v| v[:gap] }[1][:gap]
    min = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.min_by {|k,v| v[:gap] }[1][:gap]
    basis = ((max - min) / 100)
    puts " max is #{max}, min is #{min}, base value is #{basis}"
    tbl.select{|k,v| k =~ /(rate|percent|fav_page)/}.each do |k,v|
      value = (v[:gap] * basis).to_i
      v[:gap] = value
      puts "convert pct to num success! key is #{k}, value is #{value}"
    end
    return tbl
  end

  # GAP値の数値をパーセンテージへ変換
  def calc_num_to_pct(tbl)

    max = tbl.reject{|k,v| k =~ /(rate|percent)/}.max_by {|k,v| v[:gap] }[1][:gap]
    min = tbl.reject{|k,v| k =~ /(rate|percent)/}.min_by {|k,v| v[:gap] }[1][:gap]

    # 変換の基準となる値を算出
    basis = ((max - min) / 100)
    puts " max is #{max}, min is #{min}, base value is #{basis}"

    tbl.reject{|k,v| k =~ /(rate|percent)/}.each do |k,v|
      if v[:gap] == max and v[:gap] > 0 then
        value = 100
      elsif v[:gap] == min and v[:gap] == 0 then
        value = 0
      else
        value = (v[:gap] / basis).to_i
      end

      puts "Convert num to pct success! key is #{k}, row value is #{v[:gap]}, converted value is #{value}"

      v[:gap] = value
    end
    return tbl
  end

  # pageviews, sessions は gap の箇所に項目値を入れる（グラフ表示の為）
  def change_gap_to_komoku(skel)
    # skel.select{|k, v| k =~ /(^pageviews$|^pageviews |^sessions $)/}
    skel.select{|k, v| k =~ /(^pageviews$|^sessions$|^bounce_rate$)/}.each do |k, v|
      v[:gap] = v[:good].to_i + v[:bad].to_i
    end
  end

  def change_gap_to_abs(skel)
    skel.each do |k, v|
      v[:gap] = v[:gap].abs
    end
  end

  def change_gap_to_minus(skel)
    skel.each do |k, v|
      v[:gap] = - v[:gap]
    end
  end


  # バブル（散布図）チャートの総ギャップ値と相関を合わせた配列（jqplotへ渡す）
  def concat(tb, b, hsh)
    arr = []
    hsh.each do |k, v|
      arr.push( [ tb[k][:gap].to_i, b[k][:corr].to_i, 1, v ] )
      puts "array push success! hash_key is #{k}, corr_name is #{v} "
    end
    return arr
  end

  def substr_fav(dt, rank)
    begin
      shori = '人気ページランク抽出'
      r_hsh = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      dt.each do |k, v|
        r_hsh[k] = v if rank.include?(k)
      end
      return r_hsh
    rescue => e
      puts "エラー：#{shori}"
      puts e.message
    end
  end

  def seikei_rank(rank)
    arr = []
    rank.each do |k, v|
      if v[0] == 'その他' then
        key = v[0]
      else
        key = v[0] + ';;' + v[1]
      end
      arr.push(key)
    end
    return arr
  end

  def pickup_gap_per_day(corr)
    gap_day = Hash.new{ |h, k| h[k] = {} }

    corr.select{|k, v| k =~ /(day_)/}.each do |k, v|

      page, day_type = k.split(' ')

      select_day_type_for_pickup_gap_per_day(day_type, gap_day, page, v)

    end
    gap_day
    rescue => e
      puts e.message
  end

  def select_day_type_for_pickup_gap_per_day(day_type, gap_day, page, v)

    if  day_type =~ /(day_on)/
      gap_day["#{page} day_on"][:gap] = v[:gap]
    else
      gap_day["#{page} day_off"][:gap] = v[:gap]
    end
  rescue
    puts $!
    puts $@
  end

  private

    def set_data_of_calc_corr(v, cr, komoku, date)
      cr.dt_dy = v[komoku][0].to_f + v[komoku][1].to_f # 項目値(理想値＋現実値)
      cr.gp_dy = v[komoku][2].to_f # GAP
      cr.dy = v[komoku][3] # 曜日種別
      # cr.cvr_dy = 1
      cr.date = date
    end

    def hoge
      puts 'hoge'
      binding.pry
      puts 'huga'
    end



end
