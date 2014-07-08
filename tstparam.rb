  load 'user_func.rb'
  load 'create_table.rb'
  load 'insert_table.rb'
  load 'update_table.rb'
  include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils
@user = User.find(1)
@ga_profile = AnalyticsService.new.load_profile(@user)
@cond = { :start_date => Date.new(2012, 12, 5),   :end_date   => Date.new(2012, 12, 10),    :filters => {}   }
@from = @cond[:start_date]
@to = @cond[:end_date]
@cv_num = "1"
@cv_txt = ('goal' + @cv_num.to_s + '_completions')
@cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
@graphic_item = :pageviews
@favorite = Analytics::FetchKeywordForPages.results(@ga_profile, @cond)
        mets = {
          @cvr_txt.classify.to_sym => 'CVR',
          :pageviews => 'PV数',
          :pageviewsPerSession => '平均PV数',
          :sessions => '訪問回数',
          :avgSessionDuration => '平均滞在時間',
          :bounceRate => '直帰率',
          :percentNewSessions => '新規訪問率',
        }
        mets_ca = [] # アナリティクスAPIデータ取得用
        mets_sa = [] # データ構造構築用
        mets_sh = {} # jqplot用データ構築用
        mets.each do |k, v|
          mets_sh[k.to_s.to_snake_case.to_sym] = v
          mets_ca.push(k)
          mets_sa.push(k.to_s.to_snake_case.to_sym)
        end
        {
          :fav_page => '人気ページ',
          :repeat_rate => '再訪問率',
          :day => '曜日別',
        }.each do |k, v|
          mets_sh[k] = v
          mets_sa.push(k)
        end
