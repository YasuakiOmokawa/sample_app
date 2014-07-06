module InsertTable

    # ギャップなしテーブルへデータ代入
  def put_common(table, data)
    if data.total_results != 0 then
      data.each do |s|
        s.to_h.each do |k, v|
          table[k] = v
        end
      end
    end
  end

  # 共通ギャップ値テーブルへ値を代入
  def put_common_for_gap(tbl, data, all = nil)
    ['good', 'bad'].each do |t|
      if data[t].total_results != 0 then
        data[t].each do |s|
          s.to_h.each do |k, v|
            if all.nil? then
              tbl[k][t.to_sym] = v
            else
              # アナリティクスに無い項目を算出する
              al = all.to_i
              p al
              if al < 1 then al = 1 end # ゼロ除算例外の防止
              p al
              tbl[:repeat_rate][t.to_sym] = ( v.to_f / al.to_f ) * 100
            end
          end
        end
      end
    end
    return tbl
  end

  # グラフ値テーブルへ値を代入
  def put_table_for_graph(data, tbl, item, all)
    {'good' => 0, 'bad' => 1}.each do |k, v|
      if data[k].total_results != 0 then
        data[k].each do |d|
          date = d.date
          item.each do |t|
            if t == :repeat_rate then
              if all.to_f <= 0 then all = 1 end
              if d[:sessions].to_f > 0 then
                tbl[date][t][v] = (d[:sessions].to_f / all.to_f) * 100
              end
            else
              tbl[date][t][v] = d[t]
            end
          end
        end
      end
    end
  return tbl
  end

  # グラフ値テーブルへcv値を代入
  def put_cv_for_graph(data, table, cv_num, flg = 'none')
    if data.total_results != 0 then
      data.each do |d|
        date = d.date
        case flg
        when 'fvt' then # 人気ページ相関テーブルの場合
          key = d.page_title + ";;" + d.page_path
          # puts " date is #{date} key is  #{key}"
          unless table[date][key].nil?
            table[date][key][4] = d[('goal' + cv_num.to_s + '_completions').to_sym]
            # puts "value is setted. " + table[date][key][4].to_s
          end
        else
          table[date][:cv] = d[('goal' + cv_num.to_s + '_completions').to_sym]
        end
      end
    end
    return table
  end

  # 人気ページテーブルにデータ代入
  def put_favorite_table(data, tbl)
    total = 0 # total_pv数
    top_ten = 0 # 人気ページtop10のpv数
    cntr = 0

    ['good', 'bad'].each do |t|
      if data[t].total_results != 0
        data[t].each do |s|
          total += s.pageviews.to_i # トータルのPV数を取得
        end
        data[t].sort_by{ |a| a.pageviews.to_i}.reverse.each do |s|
          cntr += 1
          key = s.page_title + ";;" + s.page_path
          tbl[key][t.to_sym] = s.pageviews.to_i
          if cntr >= 10 then
            break
          end
        end
        tbl.each do |k,v|
          top_ten += v[t.to_sym].to_i
          v[t.to_sym] = ( v[t.to_sym].to_f / total.to_f ) * 100 # 人気ページのPVパーセンテージを取得
        end
        tbl["その他"][t.to_sym] = ( ( total.to_i - top_ten.to_i ).to_f / total.to_f ) * 100 # top10以下のパーセンテージを取得
      end
    end
    return tbl
  end

  # referral, social, campaign 個別テーブルへデータ代入
  def put_rsc_table(tbl, data, cv, key)
    ['good', 'bad'].each do |t|
      if data[t].total_results != 0 then
        data[t].each do |s|
          tbl[s.send(key)][t.to_sym] = s.send(cv)
        end
      end
    end
    return tbl
  end


end
