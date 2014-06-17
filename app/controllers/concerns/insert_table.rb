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
  def put_common_for_gap(table, data, all = nil)
    ['good', 'bad'].each do |t|
      if data[t].total_results != 0 then
        data[t].each do |s|
          s.to_h.each do |k, v|
            if all.nil? then
              table[k][t.to_sym] = v
            else
              # アナリティクスに無い項目を算出する
              al = all.to_i
              if al > 0 then al = 1 end
              table[:repeat_rate][t.to_sym] = ( v.to_f / al.to_f ) * 100
            end
          end
        end
      end
    end
    return table
  end

  # グラフ値テーブルへ値を代入
  def put_table_for_graph(data, tbl, item, all)
    {'good' => 0, 'bad' => 1}.each do |k, v|
      if data[k].total_results != 0 then
        data[k].each do |d|
          date = d.date
            if item == :repeat_rate then
              if all.to_f <= 0 then all = 1 end
              if d[:sessions].to_f > 0 then
                tbl[date][item][v] = (d[:sessions].to_f / all.to_f) * 100
              end
            else
              tbl[date][item][v] = d[item]
            end
        end
      end
    end
  return tbl
  end

  # グラフ値テーブルへcv値を代入
  def put_cv_for_graph(data, table, cv_num)
    if data.total_results != 0 then
      data.each do |d|
        date = d.date
        table[date][:cv] = d[('goal' + cv_num.to_s + '_completions').to_sym]
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
end
