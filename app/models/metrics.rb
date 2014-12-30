class Metrics < ActiveRecord::Base

  def initialize
    @ga = {
      :pageviews => 'PV数',
      :pageviewsPerSession => '平均PV数',
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

  def garb_result
    @ga.to_snake_case.to_sym
  end


end
