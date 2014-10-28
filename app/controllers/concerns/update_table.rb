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

  def calc_corr(tbl, col, cvr, flg = 'none')
    begin
      shori = 'バブル（散布図）チャートのために相関を出す'

      r_hsh = Hash.new{ |h,k| h[k] = {} }
      d_hsh = {} # 曜日種別の日数を保持
      ky, dy_bf, pt = '', '', 0
      cvr_dy_bf = gp_dy_bf = cv_dy_bf = 0.0
      cvr_dy = gp_dy = cv_dy = dy = nil

      # 項目別
      col.each do |t, i|

        # 日付別
        tbl.sort_by{|a, b| (b['idx']) }.each do |k, v|
           gp_dy_bf = v[t][2].to_f # GAP
           dy_bf = v[t][3] # 曜日種別
           cvr_dy_bf = 1

           # 人気ページ相関かどうかのチェック
           chk_flg(v, flg, cv_dy_bf, cvr_dy_bf, cvr)

           if not gp_dy.nil? and not cv_dy.nil? and not cvr_dy.nil? and not dy.nil?
            binding.pry # ブレークポイントスイッチ
            gp = gp_dy - gp_dy_bf
            cv = cv_dy - cv_dy_bf
            cvr = cvr_dy - cvr_dy_bf
            p "gp is #{gp}, and cv is #{cv}, and cvr is #{cvr} gp_dy_bf, gp_dy, cv_dy_bf, cv_dy, cvr_dy_bf, cvr_dy is #{gp_dy_bf} #{gp_dy} #{cv_dy_bf} #{cv_dy} #{cvr_dy_bf} #{cvr_dy}"
            pt = calc_soukan(t, gp, cvr, cv)
            ky = t.to_s + ' ' + dy_bf.to_s
            case flg
            when 'fvt' then
              # .. 人気ページのときは曜日別計算をしない
            else
              d_hsh[ky] = 1 + d_hsh[ky].to_i # 曜日別のカウンタ
              r_hsh[ky][:gap] = gp_dy_bf + r_hsh[ky][:gap].to_i # 曜日別の値
            end
            if dy == dy_bf then # 相関ポイント計算
              r_hsh[t][:corr] = pt + r_hsh[t][:corr].to_i
              case flg
              when 'fvt' then
                # ..
              else
                r_hsh[ky][:corr] = pt + r_hsh[ky][:corr].to_i # 曜日別の値
              end
            end
           end
           # binding.pry
           dy = dy_bf
        end
        gp_dy = gp_dy_bf
        cv_dy = cv_dy_bf
        cvr_dy = cvr_dy_bf
        cvr_dy_bf = gp_dy_bf = cv_dy_bf = ''
      end

      # 曜日別GAPの算出
      calc_gap_per_day(d_hsh, r_hsh, ky)

      # 相関の算出
      col.each do |t, i|
        case t
        when :pageviews, :sessions, :bounce_rate then
          souten = (tbl.size * 3).to_f
        else
          souten = (tbl.size * 2).to_f
        end
        r_hsh[t][:corr] = (r_hsh[t][:corr].to_f / souten * 100).to_i
      end
      return r_hsh
    rescue => e
      puts "エラー： #{shori}"
      puts e.message
    end
  end

  def calc_soukan(mtrcs, gp, cvr, cv)

    case mtrcs
    # 相関係数を計算(pv, sessions, bounce_rate)
    when :pageviews, :sessions, :bounce_rate then

      # gap, cv 共に共通変更あり
      if ( ( gp < 0.0 and cv < 0 ) or ( gp > 0.0 and cv > 0) ) and (cvr >= 0.0 )
        # p "e3pt"
        pt = 3
      elsif ( gp == 0.0 or cv == 0 ) and (cvr >= 0.0) # どちらかが前日と同じ
        # p "cvr_dypt"
        pt = 2
      else
        # p "cvr_dy_bfpt"
        pt = 1
      end
    else
      # 相関係数を計算(それ以外)
      if ( gp < 0.0 and cv < 0 ) or ( gp > 0.0 and cv > 0) # gap, cv 共に共通変更あり
        # p "2pt"
        pt = 2
      elsif ( gp == 0.0 or cv == 0 ) # どちらかが前日と同じ
        # p "1pt"
        pt = 1
      else
        # p "0pt"
        pt = 0
      end
    end
    return pt
  end

  # 人気ページ相関かどうかのチェック
  def chk_flg(v, flg, cv_dy_bf, cvr_dy_bf, cvr)

   case flg
   when 'fvt' then # 人気ページ相関の場合
     cv_dy_bf = v[t][4].to_i # CV

     return cv_dy_bf.to_i
   else
    # binding.pry # ブレークポイントスイッチ
     cv_dy_bf = v[:cv].to_i
     cvr_dy_bf = v[cvr][2].to_f # CVR

     return cv_dy_bf.to_i, cvr_dy_bf.to_f
   end
  end

  # 曜日別GAPの算出
  def calc_gap_per_day(d_hsh, r_hsh, ky)

    # d_hsh の中身 k.. 項目と曜日の種別 v.. 曜日の数

    d_hsh.each do |c, d|

      # binding.pry # ブレークポイントスイッチ
      if c =~ /(rate|percent|avg_|_per_)/ then

        # puts "calc average because of item is #{c}"

        if d_hsh[c] == 0 then
          d_hsh[c] = 1
        end

        avg = r_hsh[c][:gap] / d_hsh[c]

        r_hsh[c][:gap] = avg

        puts "calc gap_avg ok! key is #{d_hsh[ky]}, value is #{avg}"
      end
    end
    return r_hsh
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

    max = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.max_by {|k,v| v[:gap] }[1][:gap]
    min = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.min_by {|k,v| v[:gap] }[1][:gap]

    # 変換の基準となる値を算出
    basis = ((max - min) / 100)
    logger.info( " max is #{max}, min is #{min}, base value is #{basis}")

    tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.each do |k,v|
      if v[:gap] == max and v[:gap] > 0 then
        value = 100
      elsif v[:gap] == min and v[:gap] == 0 then
        value = 0
      else
        value = (v[:gap] / basis).to_i
      end

      logger.info( "Convert num to pct success! key is #{k}, row value is #{v[:gap]}, converted value is #{value}" )

      v[:gap] = value
    end
    return tbl
  end


  # バブル（散布図）チャートの総ギャップ値と相関を合わせた配列（jqplotへ渡す）
  # バブルにする場合は、push時に３番目にradiusを設定
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


end
