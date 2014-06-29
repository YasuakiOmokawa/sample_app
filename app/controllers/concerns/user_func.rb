module UserFunc

  # 理想値、現状値を取得
  def fetch_analytics_data(name, prof, opt, cv, filter = {}, metrics = nil, dimensions = nil)
    hash = {}
    o = opt.dup
    o[:filters] = o[:filters].merge( filter )
    {'good' => :gte, 'bad' => :lt}.each do |k, v|
      c = o.dup
      c[:filters] = o[:filters].merge( { cv.to_sym.send(v) => 1 } )

      if metrics.nil?
        hash[k] = Analytics.const_get(name).results(prof, c)
      elsif metrics == :repeat_rate then
        c[:filters] = c[:filters].merge( { :user_type.matches => 'Returning Visitor' })
        p c[:filters]
        hash[k] = Analytics.create_class(name,
          [ :sessions ],
          [:date]).results(prof, c)
      elsif dimensions.nil?
        hash[k] = Analytics.create_class(name,
          [ metrics ],
          [ dimensions ]).results(prof, c)
      else
        hash[k] = Analytics.create_class(name,
          [ metrics ],
          [:date]).results(prof, c)
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
    y, m, d = date.split("-")
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
    case tg
    when 'f'
      data.each do |w|
        arr.push([ w.page_title, w.page_title.to_s + tg ])
      end
    when 's'
      data.each do |w|
        arr.push([ w.keyword, w.keyword.to_s + tg ])
      end
    when 'r'
      data.each do |w|
        arr.push([ w.source, w.source.to_s + tg ])
      end
    when 'l'
      data.each do |w|
        arr.push([ w.social_network, w.social_network.to_s + tg ])
      end
    when 'c'
      data.each do |w|
        arr.push([ w.campaign, w.campaign.to_s + tg ])
      end
    end
    return arr
  end
end