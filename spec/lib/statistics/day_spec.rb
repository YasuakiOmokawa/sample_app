require 'spec_helper'
# load 'user_func.rb'
# load 'create_table.rb'
# load 'insert_table.rb'
# load 'update_table.rb'
# include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

describe Statistics::Day do
  # it "指定期間の日数分要素があること" do

  #   @user = User.find(3)
  #   analyticsservice = AnalyticsService.new
  #   @session = analyticsservice.login(@user)                                     # アナリティクスAPI認証パラメータ１
  #   @ga_profile = analyticsservice.load_profile(@session, @user)                                     # アナリティクスAPI認証パラメータ２
  #   @ga_goal = analyticsservice.get_goal(@ga_profile)                                     # アナリティクスに設定されているCV
  #   @from = set_date_format('2014/11/21')
  #   @to = set_date_format('2014/11/25')
  #   @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ
  #   @graphic_item  = ('pageviews').to_sym
  #   @cv_num = 1                                                     # CV種類
  #   @cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
  #   @cv_txt = ('goal' + @cv_num.to_s + '_completions')
  #   @day_type = 'all_day'

  #   metrics = Metrics.new()
  #   metrics_camel_case_datas = metrics.garb_parameter
  #   metrics_snake_case_datas = metrics.garb_result
  #   metrics_for_graph_merge = metrics.jp_caption

  #   exception_cb = Proc.new do |retries|
  #     logger.info("API request retry: #{retries}")
  #   end

  #   ### APIデータ取得部

  #   # クラス名を一意にするため、乱数を算出
  #   rndm = SecureRandom.hex(4)

  #   # CV代入用
  #   cls_name = 'CVForGraphSkeleton' + rndm.to_s
  #   # 4回までリトライできます
  #   Retryable.retryable(:tries => 5, :sleep => lambda { |n| 4**n }, :on => Garb::InsufficientPermissionsError, :matching => /Quota Error:/, :exception_cb => exception_cb ) do
  #     @cv_for_graph = Analytics.create_class(cls_name,
  #       [ (@cv_txt.classify + 's').to_sym], [:date] ).results(@ga_profile,@cond)
  #   end

  #   # スケルトン作成
  #   @table_for_graph = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
  #   create_skeleton_for_graph(@table_for_graph, @from, @to, metrics_for_graph_merge)

  #   # CV代入
  #   put_cv_for_graph(@cv_for_graph, @table_for_graph, @cv_num)

  #   # CV個数が分析対象に満たない場合、コントローラを抜ける
  #   d = Statistics::Day.new(@table_for_graph)

  #   expect(d.data.size).to eq 5
  # end
end
