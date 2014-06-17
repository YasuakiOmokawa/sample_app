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
end
