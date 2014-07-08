Pry.config.color = false
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
Pry.config.pager = false


load 'user_func.rb'
load 'create_table.rb'
load 'insert_table.rb'
load 'update_table.rb'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils
@user = User.find(1)
@ga_profile = AnalyticsService.new.load_profile(@user)
@cond = { :start_date => Date.new(2012, 12, 5),   :end_date   => Date.new(2012, 12, 15),    :filters => {}   }
@from = @cond[:start_date]
@to = @cond[:end_date]
@cv_num = "1"
@cv_txt = ('goal' + @cv_num.to_s + '_completions')
@cvr_txt = ('goal' + @cv_num.to_s + '_conversion_rate')
@graphic_item = :pageviews
@favorite = Analytics::FetchKeywordForPages.results(@ga_profile, @cond)
@top_ten = top10(@favorite)
@rank_arr = seikei_rank(@top_ten) #人気ページランクtop10
