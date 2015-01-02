module UserFunc

  def guard_for_zero_division(value)
    if value.nil? or value <= 0
      1
    else
      value
    end
  end

  def komoku_day_type(komoku, day_type)
    if day_type == 'day_on'
      (komoku.to_s + '__day_on').to_sym
    elsif day_type == 'day_off'
      (komoku.to_s + '__day_off').to_sym
    else
      komoku
    end
  end

  # 理想値、現状値を取得
  def fetch_analytics_data(name, prof, opt, cv, filter = {}, metrics = nil, dimensions = nil)

    hash = {}
    o = opt.dup
    o[:filters] = o[:filters].merge( filter )
    {'good' => :gte, 'bad' => :lt}.each do |k, v|

      # API同時接続制限対処のため、sleep 指定
      # sleep(1)

      c = o.dup
      c[:filters] = o[:filters].merge( { cv.to_sym.send(v) => 1 } )

      if metrics.nil?
        hash[k] = Analytics.const_get(name).results(prof, c)
      elsif metrics == [:repeat_rate] then

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Analytics.create_class(name,
          [ :sessions, :percent_new_sessions ],
          [:date]).results(prof, c)
      elsif dimensions.nil?

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Analytics.create_class(name,
          [ metrics ],
          [:date]).results(prof, c)
      else

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Analytics.create_class(name,
          [ metrics ],
          [ dimensions ]).results(prof, c)
      end
    end
    return hash
  end

  # グラフフォーマットを判別する
  def check_format_graph(item)
    if /(bounce_rate|repeat_rate|percent_new_sessions)/ =~ item then
      p = "percent"
    elsif /avg_session_duration/ =~ item then
      p = "time"
    else
      p = "number"
    end
    p
  end
end

module ParamUtils

  # 日付生成
  def set_date_format(date)
    y, m, d = date.split("/")
    d = Date.new(y.to_i, m.to_i, d.to_i)
    return d
  end

  # 使用端末の設定
  def set_device_type(dvc, opt)
    case dvc
    when "pc"
      opt[:filters].merge!( { :device_category.matches => 'desktop' } )
    when "sphone"
      opt[:filters].merge!( {
        :device_category.matches => 'mobile',
        :mobile_input_selector.matches => 'touchscreen'
      })
    when "mobile"
      opt[:filters].merge!( {
        :device_category.matches => 'mobile',
        :mobile_input_selector.does_not_match => 'touchscreen'
      })
    end
    return dvc
  end

  # 来訪者の設定
  def set_visitor_type(vst, opt)
    case vst
    when "new"
      opt[:filters].merge!( {:user_type.matches => 'New Visitor'} )
    when "repeat"
      opt[:filters].merge!( { :user_type.matches => 'Returning Visitor' } )
    end
    return vst
  end

  # アクションに応じた@condの設定
  def set_action(wd, opt)
    case wd
    when 'search'
      opt[:filters].merge!( {:medium.matches => 'organic'} )
    when 'direct'
      opt[:filters].merge!( {:medium.matches => '(none)'} )
    when 'referral'
      opt[:filters].merge!( {:medium.matches => 'referral'} )
    when 'social'
      opt[:filters].merge!( {:has_social_source_referral.matches => 'Yes'} )
    when 'campaign'
      opt[:filters].merge!( {:campaign.does_not_match => '(not set)'} )
    end
  end

  # 絞り込みキーワードの設定
  def set_narrow_word(wd, opt, tag)
    case tag
    when 'f'
      opt[:filters].merge!( {:page_title.matches => wd } )
    when 's'
      opt[:filters].merge!( {:keyword.matches => wd } )
    when 'r'
      opt[:filters].merge!( {:source.matches => wd } )
    when 'l'
      opt[:filters].merge!( {:social_network.matches => wd } )
    when 'c'
      opt[:filters].merge!( {:campaign.matches => wd } )
    end
  end

  def chk_num_charactor(cnt)
    if cnt == 1
      '①'
    elsif cnt == 2
      '②'
    elsif cnt == 3
      '③'
    end
  end

  # セレクトボックスの生成
  def set_select_box(data, tag)
    tg = tag.to_s
    arr = []
    cntr = 0
    case tg
    when 'r'
      cntr += 1
      data.each do |k, w|
        arr.push([ w[:cap], w[:value].to_s + tg ])
        if cntr >= 3 then break end
      end
    when 'l'
      cntr += 1
      data.each do |w|
        arr.push([ w.social_network, w.social_network.to_s + tg ])
        if cntr >= 3 then break end
      end
    end
    arr
  end

  # ユニークキーを取得する
  def create_cache_key(analyze_type)

    # ユーザ単位で一意にするため指定
    usrid = params[:id].to_s

    uniq = usrid + params[:from].to_s + params[:to].to_s + analyze_type

    if analyze_type == 'kobetsu'
      uniq += params[:cv_num].to_s + params[:act].to_s + params[:kwds_len].to_s
    end
    uniq
  end

  # データ指標の取得
  def get_metricses
    {
      :pageviews => 'PV数',
      :pageviewsPerSession => '平均PV数',
      :sessions => 'セッション',
      :avgSessionDuration => '平均滞在時間',
      :bounceRate => '直帰率',
      :percentNewSessions => '新規ユーザー',
      :users => 'ユーザー',
    }
  end

  def get_metrics_not_ga
    {
      :repeat_rate => 'リピーター',
    }
  end

  def get_day_types
    %w(
      all_day
      day_on
      day_off
    )
  end

  def get_analyzable_day_types(table)
    res = get_day_types
    get_day_types.each do |t|
      d = Statistics::DayFactory.new(table, :sessions, t).data
      res.delete(t) if d.get_cves.sum / guard_for_zero_division(d.get_metrics.sum) < 0.43
      # puts "day_type: #{t} cv_sum/metrics_sum: #{d.get_cves.sum / guard_for_zero_division(d.get_metrics.sum)}"
    end
    res
  end

  def group_by_year_and_month(data)
    data.group_by{|k, v| k.to_s[0..5]}.map{|k, v| k}
  end

  # 人気ページテーブル用にtop10 生成
  # def top10(dt)
  #   r_hsh = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
  #   cntr = 0
  #   dt.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
  #     cntr += 1
  #     r_hsh[cntr] = [t.page_title, t.page_path, t.pageviews]
  #     if cntr >= 10 then break end
  #   end
  #   cntr = cntr + 1
  #   r_hsh[cntr] = ['その他', '']
  #   return r_hsh
  # end

  # 人気ページ用に上位タイトルを切り出す
  # def head_favorite_table(data, limit)
  #   r_hsh = Hash.new { |h,k| h[k] = {}}
  #   cntr = 0
  #   data.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
  #     cntr += 1
  #     r_hsh[cntr] = [t.page_title, t.page_path, t.pageviews]
  #     if cntr >= limit then break end
  #   end
  #   r_hsh
  # end
end
