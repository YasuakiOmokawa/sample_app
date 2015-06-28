module ExcelFunc

  def self.excel_upper_quartile(array)
    excel_quartile(:upper, array)
  end

  def self.excel_lower_quartile(array)
    excel_quartile(:lower, array)
  end

  def self.excel_quartile(extreme, array)
    return nil if array.empty?
    sorted_array = array.sort
    u = case extreme
    when :upper then 3 * sorted_array.length + 1
    when :lower then sorted_array.length + 3
    else raise "ArgumentError"
    end
    u *= 0.25
    if (u-u.truncate).is_a?(Integer)
      return sorted_array[(u-u.truncate)-1]
    else
      sample = sorted_array[u.truncate.abs-1]
      sample1 = sorted_array[(u.truncate.abs)]
      return sample+((sample1-sample)*(u-u.truncate))
    end
  end
end

module UserFunc

  Oauths = Struct.new(:oauth2, :user_data)

  def get_ga_profiles
    oauth2 = Ast::Ganalytics::Garbs::GoogleOauth2InstalledCustom.new(@user.gaproject)
    gaservice = Ast::Ganalytics::Garbs::Session.new(Oauths.new(oauth2, @user))
    @ga_profile ||= gaservice.load_profile # Garb でデータを取得するときに使う
  end

  def change_to_garb_kwds(src, param)
    res = Array(src).reduce([]) do |acum, item|
      acum << item.send(param)
      acum
    end
    res
  end

  def reduce_with_kwd(src, kwd, param)
    res = Array(src).reduce([]) do |acum, item|
    if item.send(param) == kwd.to_s
      item.day_type = chk_day(item.date.to_date)
      acum << item
    end
      acum
    end
    res
  end

  def to_garb_attr(prm)
    prm.to_s.to_snake_case.to_sym
  end

  def chk_not_a_number(target)
    if target.nan?
      0.0
    else
      target
    end
  end

  def check_number_sign(n)
    if n >= 0
      'plus'
    else
      'minus'
    end
  end

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
        hash[k] = Ast::Ganalytics::Garbs::Data.const_get(name).results(prof, c)
      elsif metrics == [:repeat_rate] then

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Ast::Ganalytics::Garbs::Data.create_class(name,
          [ :sessions, :percent_new_sessions ],
          [:date]).results(prof, c)
      elsif dimensions.nil?

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Ast::Ganalytics::Garbs::Data.create_class(name,
          [ metrics ],
          [:date]).results(prof, c)
      else

        # クラス名を一意にするため、乱数を算出
        rndm = SecureRandom.hex(4)
        name = name + rndm.to_s

        hash[k] = Ast::Ganalytics::Garbs::Data.create_class(name,
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

  private

end

module ParamUtils

  def add_category_condition(param)
    # 分析カテゴリ
    categories = {
      all: {},
      search: {:medium.matches => 'organic'},
      direct: {:medium.matches => '(none)'},
      referral: {:medium.matches => 'referral'},
      social: {:has_social_source_referral.matches => 'Yes'},
    }
    @cond[:filters].merge!(categories[param.to_sym])
    param
  end

  def add_device_condition(param)
    # デバイス
    devices = {
      pc: { :device_category.matches => 'desktop' },
      sphone: {
        :device_category.matches => 'mobile',
        :mobile_input_selector.matches => 'touchscreen'
      },
      mobile: {
       :device_category.matches => 'mobile',
        :mobile_input_selector.does_not_match => 'touchscreen'
      },
      all: {}
    }
    @cond[:filters].merge!(devices[param.to_sym])
    param
  end

  def add_user_condition(param)
    # 訪問者
    users = {
      new: {:user_type.matches => 'New Visitor'},
      repeat: { :user_type.matches => 'Returning Visitor' },
      all: {},
    }
    @cond[:filters].merge!(users[param.to_sym])
    param
  end

  def add_keyword_condition(param)
    unless param == 'nokwd'
      set_narrow_word(param, @cond, param.slice!(0))
    end
    param
  end

  # 日付生成
  def set_date_format(date)
    y, m, d = date.split("/")
    Date.new(y.to_i, m.to_i, d.to_i)
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
    data.group_by{|item| item.date[0..5]}.map{|k, v| k}
  end

  def is_not_uniq?(data)
    return true if Array(data).uniq.size > 1
  end

  def validate_cv
    Rails.logger.info( "CVデータをバリデートします")
    get_day_types.each do |day_type|
      cves = cves_for_validate(@ast_data, day_type)
      unless is_not_uniq?(cves)
        validate_cv_msg(day_type)
        @valid_analyze_day_types.delete(day_type)
      end
      Rails.logger.info( "CVバリデートOK。")
    end
    Rails.logger.info( "CVバリデート完了。")
  end

  def validate_cv_msg(day_type)
    Rails.logger.info( "CVが一意なので分析できません。#{day_type}は分析対象から外します。")
  end

  def cves_for_validate(data, day_type)
    Statistics::DayFactory.new(data, :sessions, day_type, @cv_num).data.get_cves
  end

  def metrics_for_validate(data, day_type, metrics)
    Statistics::DayFactory.new(data, metrics, day_type, @cv_num).data
  end

  def delete_uniq_metrics(data, metrics, metricses)
    unless is_not_uniq?(data)
      validate_uniq_metrics_msg(metrics)
      metricses.delete(metrics)
    end
  end

  def validate_uniq_metrics_msg(metrics)
    Rails.logger.info( "指標#{metrics}は一意なので分析対象から外します。")
  end

  def delete_too_much_zero_metrics(data, metrics, metricses)
    if ExcelFunc.excel_upper_quartile(data) == 0
      validate_too_much_zero_metrics_msg(metrics)
      metricses.delete(metrics)
    end
  end

  def validate_too_much_zero_metrics_msg(metrics)
    Rails.logger.info( "指標#{metrics}はゼロが多すぎるので分析対象から外します。")
  end

  def delete_invalid_metrics_multiple(data, metrics, metricses, cves)
    unless cves.zip(data).uniq.size >= 3
      validate_invalid_metrics_multiple_msg(metrics)
      metricses.delete(metrics)
    end
  end

  def validate_invalid_metrics_multiple_msg(metrics)
    Rails.logger.info( "指標#{metrics}はCVデータとの一意な組み合わせが少ないので分析対象から外します。")
  end

  def validate_metrics
    Rails.logger.info( "指標データをバリデートします")
    @valids.each do |valid|
      @metrics_snake_case_datas.each do |metrics|
        cves = cves_for_validate(@ast_data, valid.day_type)
        df = metrics_for_validate(@ast_data, valid.day_type, metrics)
        delete_uniq_metrics(df.get_metrics, metrics, valid.metricses)
        delete_invalid_metrics_multiple(df.get_metrics, metrics, valid.metricses, cves)
        delete_too_much_zero_metrics(df.get_metrics, metrics, valid.metricses)
      end
      Rails.logger.info( "#{valid.day_type}の指標バリデートOK。")
    end
    Rails.logger.info( "指標バリデート完了。")
  end

  def reset_filter_option
    logger.info( "filters option reset start. now is #{@cond}")
    @cond[:filters] = {}
    logger.info( "filters option reset end. now is #{@cond}")
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
        valids << Valids.new(day_type, @metricses.dup)
      end
    end
  end

  class IQR
    include ExcelFunc
    IQR = Struct.new(:upper, :lower, :range_value)

    def initialize(obj)
      @obj = obj
    end

    def create
      IQR.new(ExcelFunc.excel_upper_quartile(@obj.get_metrics),
        ExcelFunc.excel_lower_quartile(@obj.get_metrics),
        ExcelFunc.excel_upper_quartile(@obj.get_metrics) - ExcelFunc.excel_lower_quartile(@obj.get_metrics)
      )
    end
  end

  def detect_outlier_with_iqr(df, metrics_and_cv)

    iqr = IQR.new(df).create

    detected = metrics_and_cv.reduce([]) do |acum, data|
      if data.metrics >= iqr.upper + (iqr.range_value * 1.5) or data.metrics <= iqr.lower - (iqr.range_value * 1.5)
        Rails.logger.info( "#{df.komoku} の #{data.metrics} は、外れ値として除外されました。")
      else
        acum << data
      end
      acum
    end
    return detected
  end

  def get_detected_metrics(detected)
    metrics = detected.reduce([]) do |acum, data|
      acum << data.metrics
      acum
    end
    metrics
  end

  def get_detected_cves(detected)
    cv = detected.reduce([]) do |acum, data|
      acum << data.cv
      acum
    end
    cv
  end

  def set_from_to(content, params)
    if content.nil?
      from = params[:from].present? ? set_date_format(params[:from]) : Date.today.prev_month
      to = params[:to].present? ? set_date_format(params[:to]) : Date.today
    else
      from = set_date_format(content.upload_file.first[0])
      to = set_date_format(content.upload_file.last[0])
    end
    [from, to]
  end

  def set_key_for_data_cache(item, option)
    if option.try(:id)
      "#{item}&custom_id=#{option.id}"
    else
      item
    end
  end

  def padding_date_format(d)
    t = d.split('/')
    "#{t[0]}/#{t[1].rjust(2, '0')}/#{t[2].rjust(2, '0')}"
  end

  # def create_parameter_with_request_hash(req)
  #   req
  # end
end
