module CreateTable

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




  # グラフ値テーブルスケルトンを作成
  def create_skeleton_for_graph(hsh, from, to, clm)
    idx = 1
    (from..to).each do |t|
    clm.each do |u|
        dts = t.to_s.gsub( /-/, "" )
        if (t.wday == 0 or t.wday == 6) or HolidayJapan.check(t) then
          hsh[dts][u] = [0, 0, 0, 'day_off']
        else
          hsh[dts][u] = [0, 0, 0, 'day_on']
        end
        hsh[dts][:cv] = 0
        hsh[dts]["idx"] = idx
    end
    idx += 1
    end
    return hsh
  end

  # バブル（散布図）相関スケルトンを作成
  def create_bubble_corr(hsh, from, to, clm)
    idx = 1
    (from..to).each do |t|
    clm.each do |u,i|
        dts = t.to_s.gsub( /-/, "" )
        if (t.wday == 0 or t.wday == 6) or HolidayJapan.check(t) then
          hsh[dts][u] = [0, 0, 0, 'day_off']
        else
          hsh[dts][u] = [0, 0, 0, 'day_on']
        end
        hsh[dts][:cv] = 0
        hsh[dts]["idx"] = idx
    end
    idx += 1
    end
    return hsh
  end


  # 曜日別の値を出すテーブルを作成
  def create_table_by_days(table, data, item)
    [:day_on, :day_off].each do |t|
      [:good, :bad, :gap].each do |u|
        table[t][u] = 0
      end
    end
    data.each do |k, v|
      if v[item][3] == 'day_on' then
        table[:day_on][:good] += v[item][0].to_i
        table[:day_on][:bad] += v[item][1].to_i
        table[:day_on][:gap] += v[item][2].to_i
      else
        table[:day_off][:good] += v[item][0].to_i
        table[:day_off][:bad] += v[item][1].to_i
        table[:day_off][:gap] += v[item][2].to_i
      end
    end
    return table
  end

  # 人気ページテーブルを生成
  def create_skeleton_favorite_table(data, table)
    cntr = 0
    data.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
      cntr += 1
      key = t.page_title + ";;" + t.page_path
      table[key][:index] = cntr
      [:good, :bad, :gap].each do |s|
        table[key][s] = 0
      end
      if cntr >= 10 then break end
    end
    table["その他"][:index] = cntr + 1
    [:good, :bad, :gap].each do |s|
      table["その他"][s] = 0
    end
    return table
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
