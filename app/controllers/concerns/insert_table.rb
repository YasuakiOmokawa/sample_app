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
            if k != 'repeat_rate'.to_sym

              # 再訪問率以外の計算
              tbl[k][t.to_sym] = v

              # 再訪問率の計算方式を、一時的にセッションベースにするためコメントアウト
              # al = all.to_i
              # p al
              # if al < 1 then al = 1 end # ゼロ除算例外の防止
              # p al
              # tbl[:repeat_rate][t.to_sym] = ( v.to_f / al.to_f ) * 100
            end
          end

          # 再訪問率の計算
          # セッションベースで計算(100 - 新規訪問率) 単位：%
          # all_sessionsが0以上、もしくはセッション値が０より上の場合
          if ( not all.nil? && all.to_i > 0 )  || tbl[:sessions][t.to_sym].to_i > 0 then
            tbl[:repeat_rate][t.to_sym] = 100 - tbl[:percent_new_sessions][t.to_sym].to_i
          else
            tbl[:repeat_rate][t.to_sym] = 0
          end
        end
      end
    end
    return tbl
  end

  # def pick_value(d, date, item, komoku, value)

  #   if (komoku.nil? and value.nil?) and (d[komoku] == value and d[:date] == date)
  #     res = d[item].to_f.round(1)
  #   else
  #     res = 0
  #   end
  #   binding.pry
  #   res
  # end

  def put_table_for_special(data, tbl, item, second_komoku, second_value)
    {'good' => 0, 'bad' => 1}.each do |k, v|
      data[k].each do |d|
        date = d.date.to_s
        item.each do |t|
          if d[second_komoku] == second_value
            tbl[date][t][v] = d[t].to_f.round(1)
          end
        end
      end unless data[k].total_results == 0
    end
    tbl
  end

  def put_table_for_graph(data, tbl, item)
    {'good' => 0, 'bad' => 1}.each do |k, v|
      data[k].each do |d|
        date = d.date.to_s
        item.each do |t|
          if t == 'repeat_rate'.to_sym then
            tbl[date][t][v] = calc_repeat_rate(d)
          else
            tbl[date][t][v] = d[t].to_f.round(1)
          end
        end
      end unless data[k].total_results == 0
    end
    tbl
  end

  def calc_repeat_rate(d)
    # 再訪問率をセッションベースで計算(100 - 新規訪問率) 単位：%
    if d[:sessions].to_i > 0
      (100 - d[:percent_new_sessions].to_f).round(1)
    else
      0
    end
  end

  # グラフ値テーブルへ値を代入
  # def put_table_for_graph(data, tbl, item)
  #   {'good' => 0, 'bad' => 1}.each do |k, v|
  #     data[k].each do |d|
  #       date = d.date
  #       item.each do |t|
  #         if t == 'repeat_rate'.to_sym then
  #           tbl[date][t][v] = calc_repeat_rate(d)
  #         else
  #           tbl[date][t][v] = d[t].to_f.round(1)
  #         end
  #       end
  #     end unless data[k].total_results == 0
  #   end
  # return tbl
  # end

  # グラフ値テーブルへcv値を代入
  def put_cv_for_graph(data, table, cv_num)
    data.each do |d|
      date = d.date
      table[date][:cv] = d[('goal' + cv_num.to_s + '_completions').to_sym]
    end unless data.total_results == 0
    table
  end

  def put_favorite_table_for_skelton(data, table)

    ['good', 'bad'].each do |t|
      if data[t].total_results != 0
        table.each do |k, v|
          title, path = k.split(';;')
          value = data[t].results.find{|u| u.page_path == path}
          table[k][t.to_sym] = value.sessions.to_i unless value.nil?
        end
      end
    end
    table
  end

  def put_landing_table(data, table)

    idx = 0
    data.sort_by{ |a| [ -(a.bounce_rate.to_f), -(a.avg_session_duration.to_f) ]}.each do |t|
      table[idx][:landing_page_path] = t.landing_page_path
      table[idx][:page_title] = t.page_title
      table[idx][:bounce_rate] = chg_percent(t.bounce_rate)
      table[idx][:avg_session_duration] = chg_time(t.avg_session_duration)
      idx += 1
    end unless data.total_results == 0
    table
  end

  def put_landing_table_for_skelton(data, table)

    ['good', 'bad'].each do |t|
      if data[t].total_results != 0
        table.each do |k, v|
          title, path = k.split(';;')
          value = data[t].results.find{|u| u.landing_page_path == path}
          table[k][t.to_sym] = value.bounce_rate.to_f.round(1) unless value.nil?
        end
      end
    end
    table
  end


  # 人気ページテーブルにデータ代入
  # def put_favorite_table(data, tbl, flg = 'none')
  #   total = 0 # total_pv数
  #   top_ten = 0 # 人気ページtop10のpv数
  #   cntr = 0
  #   table = '' # データ構造（フラグ識別）
  #   gd_bd = '' # 理想現実フラグ
  #   date = '' # 日時
  #   pv_val = 0 # pvパーセンテージ

  #   ['good', 'bad'].each do |t|
  #     if data[t].total_results != 0
  #       total = c_total(data[t])
  #       data[t].sort_by{ |a| a.pageviews.to_i}.reverse.each do |s|
  #         cntr += 1
  #         key = s.page_title + ";;" + s.page_path

  #         begin
  #           shori = '全体PVからのパーセンテージを取得'
  #           pv_val = ( s.pageviews.to_f / total.to_f ) * 100
  #           case flg
  #           when 'date' then # 相関テーブルの場合
  #             date = s.date
  #             if t == 'good' then
  #               gd_bd = 0
  #             else
  #               gd_bd = 1
  #             end
  #             tbl[date][key][gd_bd] = pv_val unless tbl[date][key][gd_bd].nil?
  #           else # 相関テーブルではない（日時がない）場合
  #             tbl[key][t.to_sym] = pv_val unless tbl[key][t.to_sym].nil?
  #           end
  #           top_ten += s.pageviews.to_i
  #           puts "data insert successed! date is #{date} key is #{key} pv_val is #{pv_val} top_ten is now #{top_ten}"
  #           if cntr >= 10 then
  #             puts "calc top_ten successed!"
  #             break
  #           end
  #         rescue => e
  #           puts "エラー：　#{shori}"
  #           puts e.message
  #           puts e.backtrace
  #         end
  #       end
  #       begin
  #         shori = 'top10以下のパーセンテージを取得'
  #         # その他の計算は独立で行うため、再度case文を実施
  #         pv_val = ( ( total.to_i - top_ten.to_i ).to_f / total.to_f ) * 100
  #         case flg
  #         when 'date' then
  #           # 相関ページではその他ページを表示させないので何もしない
  #         else
  #           puts "sonota table is #{table}"
  #           tbl['その他'][t.to_sym] = pv_val unless tbl['その他'][t.to_sym].nil?
  #           puts "sonota data insert successed! value is #{pv_val}"
  #         end
  #       rescue => e
  #         puts "エラー：　#{shori}"
  #         puts e.message
  #       end
  #     end
  #   end
  #   return tbl
  # end

  # # 人気ページ_トータルのPV数を取得
  # def c_total(dt)
  #   total = 0
  #   dt.each do |s|
  #     total += s.pageviews.to_i
  #   end
  #   puts "total pv is #{total}"
  #   return total
  # end

  # # referral, social, campaign 個別テーブルへデータ代入
  # def put_rsc_table(tbl, data, cv, key)
  #   ['good', 'bad'].each do |t|
  #     if data[t].total_results != 0 then
  #       data[t].each do |s|
  #         tbl[s.send(key)][t.to_sym] = s.send(cv)
  #       end
  #     end
  #   end
  #   return tbl
  # end

end
