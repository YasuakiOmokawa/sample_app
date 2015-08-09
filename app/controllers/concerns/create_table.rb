module CreateTable

  def anlyz_sessions_per_page_and_date(cond)
    Ast::Ganalytics::Garbs::Data.create_class('CVSession',
      [:sessions], [:pagePath, :date]).results(
        @ga_profile, Ast::Ganalytics::Garbs::Cond.new(
          cond, @cv_txt).limit!(100).sort_desc!(:sessions).res)
  end

  def anlyz_sessions_per_page(cond)
    Ast::Ganalytics::Garbs::Data.create_class('AllSession',
      [:sessions], [:pagePath]).results(
        @ga_profile, Ast::Ganalytics::Garbs::Cond.new(
          cond, @cv_txt).limit!(100).sort_desc!(:sessions).res)
  end

  Graph = Struct.new(:data, :day_type)
  def create_data_for_graph_display(datas, param)
    datas.reduce({}) do |acum, item|
      acum[item.date.to_i] = Graph.new(item.send(param), item.day_type)
      acum
    end
  end

  # 土日祝日判定
    # wday 0 .. sun, 'day_sun'
    # wday 6 .. sat, 'day_sat'
    # 祝日 .. 'day_hol'
    # 平日 .. 'day_on'
  def chk_day(a)
    if a.wday == 0
      'day_sun'
    elsif a.wday == 6
      'day_sat'
    elsif HolidayJapan.check(a)
      'day_hol'
    else
      'day_on'
    end
  end
end
