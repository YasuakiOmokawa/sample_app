module UserFunc

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
      elsif metrics == :repeat_rate then
        c[:filters] = c[:filters].merge( { :user_type.matches => 'Returning Visitor' })
        p c[:filters]

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Analytics.create_class(name,
          [ :sessions ],
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
    return p
  end

  # グラフテーブルからグラフ表示プログラム用の配列を出力
  def create_array_for_graph(hash, table, param)
    table.sort_by{ |a, b| b[:idx].to_i }.each do |k, v|
      date =  k.to_i
      param = param.to_sym
      hash[date] = [ v[param][2], v[:cv].to_i ]
    end
    return hash
  end
end

module StringUtils
  def to_snake_case
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end
String.send :include, StringUtils

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

  # セレクトボックスの生成
  def set_select_box(data, tag)
    tg = tag.to_s
    arr = []
    cntr = 0
    case tg
    when 'f'
      # 人気ページテーブルと同じ順番
      data.sort_by{ |a| a.pageviews.to_i}.reverse.each do |w|
        cntr += 1
        arr.push([ w.page_title, w.page_title.to_s + tg ])
        if cntr >= 10 then break end
      end
    when 's'
      cntr += 1
      data.sort_by{ |a|
        [ -(a.sessions.to_i),
          -(a.adsense_ads_clicks.to_i),
          -(a.adsense_ctr.to_f) ] }.each do |w|
        arr.push([ w.keyword, w.keyword.to_s + tg ])
        if cntr >= 5 then break end
      end
    when 'r'
      cntr += 1
      data.each do |w|
        arr.push([ w.source, w.source.to_s + tg ])
        if cntr >= 5 then break end
      end
    when 'l'
      cntr += 1
      data.each do |w|
        arr.push([ w.social_network, w.social_network.to_s + tg ])
        if cntr >= 5 then break end
      end
    when 'c'
      cntr += 1
      data.each do |w|
        arr.push([ w.campaign, w.campaign.to_s + tg ])
        if cntr >= 5 then break end
      end
    end
    return arr
  end

  # 人気ページテーブル用にtop10 生成
  def top10(dt)
    r_hsh = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
    cntr = 0
    dt.sort_by{ |a| a.pageviews.to_i}.reverse.each do |t|
      cntr += 1
      r_hsh[cntr] = [t.page_title, t.page_path]
      if cntr >= 10 then break end
    end
    cntr = cntr + 1
    r_hsh[cntr] = ['その他', '']
    return r_hsh
  end

  # ユニークキーを取得する
  def create_cache_key(analyze_type)

    # ユーザ単位で一意にするため指定
    usrid = params[:id].to_s

    uniq = usrid + params[:from].to_s + params[:to].to_s + analyze_type

    if analyze_type == 'kobetsu'
      uniq = uniq + params[:cv_num].to_s + params[:act].to_s + params[:kwds_len].to_s
    end
    uniq
  end

end
