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

  # グラフ値テーブルのGAP値を計算
  def calc_gap_for_graph(table, clm)
    table.each do |k, v|
      date = k.to_s # きちんと変換してやんないとnilClass エラーになるので注意
      clm.each do |u|
        table[date][u][2] = table[date][u][1].to_f - table[date][u][0].to_f
      end
    end
    return table
  end

  # グラフ値テーブルのフォーマットを変更
  def change_format(table, item, format)
    table.each do |k, v|
      (0..2).each do |t|
        value = v[item][t]
        case format
        when "time" then
          str = sprintf("%02d", ( value.to_i.abs / 60 ) ) + ':' + sprintf("%02d", ( value.to_i.abs % 60 ))
          if value.to_i  < 0 then
            str = "-" + str
          end
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
  def calc_corr(tbl, col, cvr)
    r_hsh = Hash.new{ |h,k| h[k] = {} }
    e1 = d1 = f1 = 0.0
    e2 = d2 = f2 = nil
    pt = 0
    # 項目別
    col.each do |t|
      # 日付別
      tbl.sort_by{|a, b| -(b['idx']) }.each do |k, v|
         d1 = v[t][2].to_f
         e1 = v[cvr][2].to_f
         f1 = v[:cv].to_i
         if not d2.nil? and not f2.nil? and not e2.nil?
          d = d2 - d1
          f = f2 - f1
          e = e2 - e1
          p "d is #{d}, and f is #{f}, and e is #{e} d1, d2, f1, f2, e1, e2 is #{d1} #{d2} #{f1} #{f2} #{e1} #{e2}"
          pt = calc_soukan(t, d, e, f)
        Pry.rescue do
          r_hsh[t][:corr] = pt + r_hsh[t][:corr].to_i
        end
         end
      end
      d2 = d1
      f2 = f1
      e2 = e1
      e1 = d1 = f1 = ''
    end
    # 相関の算出
    col.each do |t|
      case t
      when :pageviews, :sessions, :bounce_rate then
        souten = (tbl.size * 3).to_f
      else
        souten = (tbl.size * 2).to_f
      end
      r_hsh[t][:corr] = (r_hsh[t][:corr].to_f / souten * 100).to_i
    end
    return r_hsh
  end

  def calc_soukan(t, dd, ee, ff)
    case t
    # 相関係数を計算(pv, sessions, bounce_rate)
    when :pageviews, :sessions, :bounce_rate then
      if ( ( dd < 0.0 and ff < 0 ) or ( dd > 0.0 and ff > 0) ) and (ee >= 0.0 ) # gap, cv 共に共通変更あり
        p "e3pt"
        pt = 3
      elsif ( dd == 0.0 or ff == 0 ) and (ee >= 0.0) # どちらかが前日と同じ
        p "e2pt"
        pt = 2
      else
        p "e1pt"
        pt = 1
      end
    else
      # 相関係数を計算(それ以外)
      if ( dd < 0.0 and ff < 0 ) or ( dd > 0.0 and ff > 0) # gap, cv 共に共通変更あり
        p "2pt"
        pt = 2
      elsif ( dd == 0.0 or ff == 0 ) # どちらかが前日と同じ
        p "1pt"
        pt = 1
      else
        p "0pt"
        pt = 0
      end
    end
    return pt
  end

  # GAP値のパーセンテージを値へ変換
  def calc_pct_to_num(tbl)
    max = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.max_by {|k,v| v[:gap] }[1][:gap]
    min = tbl.reject{|k,v| k =~ /(rate|percent|fav_page)/}.min_by {|k,v| v[:gap] }[1][:gap]
    basis = ((max - min) / 100)
    tbl.select{|k,v| k =~ /(rate|percent|fav_page)/}.each do |k,v|
      v[:gap] = (v[:gap] * basis).to_i
    end
    return tbl
  end

  # バブル（散布図）チャートの総ギャップ値と相関を合わせた配列（jqplotへ渡す）
  def concat(tb, b, hsh)
    arr = []
    hsh.each do |k, v|
      arr.push( [ tb[k][:gap].to_i, b[k][:corr].to_i, v ] )
    end
    return arr
  end

end
