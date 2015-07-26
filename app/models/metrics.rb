class Metrics < ActiveRecord::Base

  def initialize
    @ga = {
      :pageviews => 'ページビュー数',
      :pageviewsPerSession => '平均ページビュー数',
      :sessions => 'セッション',
      :avgSessionDuration => '平均滞在時間',
      :bounceRate => '直帰率',
      :percentNewSessions => '新規ユーザー',
      :users => 'ユーザー',
    }

    @not_ga = {
      :repeat_rate => 'リピーター',
    }
  end

  def garb_parameter
    @ga.keys
  end

  def snake_garb_parameter
    garb_parameter.map{ |t| t.to_s.to_snake_case.to_sym }
  end

  def not_ga_keys
    @not_ga.keys
  end

  def garb_result
    snake_garb_parameter.concat(not_ga_keys)
  end

  def jp_caption
    jp_caption_ga.merge(jp_caption_not_ga)
  end

  def jp_caption_ga
    hsh = {}
    @ga.each do |k, v|
      hsh[k.to_s.to_snake_case.to_sym] = {jp_caption: v}
    end
    hsh
  end

  def jp_caption_not_ga
    hsh = {}
    @not_ga.each do |k, v|
      hsh[k.to_s.to_snake_case.to_sym] = {jp_caption: v}
    end
    hsh
  end

end
