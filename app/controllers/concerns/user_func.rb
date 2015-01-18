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
    when 'all'
      opt[:filters].merge!( {} )
    when 'search'
      opt[:filters].merge!( {:medium.matches => 'organic'} )
    when 'direct'
      opt[:filters].merge!( {:medium.matches => '(none)'} )
    when 'referral'
      opt[:filters].merge!( {:medium.matches => 'referral'} )
    when 'social'
      opt[:filters].merge!( {:has_social_source_referral.matches => 'Yes'} )
    end
  end

  # 絞り込みキーワードの設定
  def set_narrow_word(wd, opt, tag)
    case tag
    when 'r'
      opt[:filters].merge!( {:source.matches => wd } )
    when 'l'
      opt[:filters].merge!( {:social_network.matches => wd } )
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

  def group_by_year_and_month(data)
    data.group_by{|k, v| k.to_s[0..5]}.map{|k, v| k}
  end

  def is_not_uniq?(data)
    return true if Array(data).uniq.size > 1
  end

  def validate_cv
    puts "CVデータをバリデートします"
    get_day_types.each do |day_type|
      cves = Statistics::DayFactory.new(@table_for_graph, :sessions, day_type).data.get_cves
      unless is_not_uniq?(cves)
        puts "CVが一意なので分析できません。#{day_type}は分析対象から外します。"
        @valid_analyze_day_types.delete(day_type)
      end
      puts "CVバリデートOK。"
    end
    puts "CVバリデート完了。"
  end

  def delete_invalid_metrics(data, metrics, metricses)
    # data = %w(1.0 1.0)
    unless is_not_uniq?(data)
      metricses.delete(metrics)
      puts "指標#{metrics}は一意なので分析対象から外します。"
    end
  end

  def validate_metrics
    puts "指標データをバリデートします"
    @valids.each do |valid|
      @metrics_snake_case_datas.each do |metrics|
        df = Statistics::DayFactory.new(@table_for_graph, metrics, valid.day_type).data
        delete_invalid_metrics(df.get_metrics, metrics, valid.metricses)
      end
      puts "#{valid.day_type}の指標バリデートOK。"
    end
    puts "指標バリデート完了。"
  end

  def validate_metrics_multiple_of_cv
  end

  def reset_filter_option
    puts "filters option reset start. now is #{@cond}"
    @cond[:filters] = {}
    puts "filters option reset end. now is #{@cond}"
  end

  class ValidAnalyzeMaterial
    require('set')

    Valids = Struct.new(:day_type, :metricses)

    def initialize(days, metricses)
      @days = days
      @metricses = metricses
    end

    def create
      @days.reduce(Set.new) do |valids, day_type|
        valids << Valids.new(day_type, @metricses)
      end
    end
  end

  # # REFERENCE_VALUE = 0.43
  # # REFERENCE_VALUE = 0.0
  # def get_analyzable_day_types(table)
  #   res = get_day_types
  #   get_day_types.each do |t|
  #     d = Statistics::Day.new(table).data
  #     res.delete(t) unless d.get_cves(d.day_on)
  #     puts "day_type: #{t} "
  #   end
  #   res
  # end


  # def validate_metrics(day_type, metricses, table)
  #   validated_metrics = metricses.dup
  #   metricses.each do |metrics|
  #     df = Statistics::DayFactory.new(table, metrics, day_type).data
  #     chk_valid_metrics(df.get_metrics, validated_metrics, metrics)
  #   end
  #   validated_metrics
  # end


end
