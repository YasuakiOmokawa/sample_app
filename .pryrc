begin
  require 'awesome_print'
  require 'hirb'
rescue LoadError
else
  AwesomePrint.pry!
end

if defined? Hirb
  # Slightly dirty hack to fully support in-session Hirb.disable/enable toggling
  Hirb::View.instance_eval do
    def enable_output_method
      @output_method = true
      @old_print = Pry.config.print
      Pry.config.print = proc do |output, value|
        Hirb::View.view_or_page_output(value) || @old_print.call(output, value)
      end
    end

    def disable_output_method
      Pry.config.print = @old_print
      @output_method = nil
    end
  end

  Hirb.enable
end

Pry.config.pager = false

def Pry.set_color sym, color
  CodeRay::Encoders::Terminal::TOKEN_COLORS[sym] = color.to_s
  { sym => color.to_s }
end

Pry.set_color :constant, "\e[1;32;4m"
Pry.set_color :integer, "\e[1;33m"
Pry.set_color :imaginary, "\e[1;33m"
Pry.set_color :annotation, "\e[32m"
Pry.set_color :function, "\e[1;32m"
Pry.set_color :doctype, "\e[1;32m"
Pry.set_color :id, "\e[1;32m"
Pry.set_color :pseudo_class, "\e[1;32m"
Pry.set_color :type, "\e[1;32m"
Pry.set_color :variable, "\e[32m"

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

# テスト用読み込みコード

load 'user_func.rb'
load 'create_table.rb'
load 'insert_table.rb'
load 'update_table.rb'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils, ExcelFunc

@from = Date.today.prev_month
@to = Date.today
@user = User.find(3)
get_ga_profiles
@cond = { :start_date => @from, :end_date   => @to, :filters => {}, }                  # アナリティクスAPI 検索条件パラメータ

params = {
  cv_num: 1,
  category: "search",
  devfltr: "pc",
  usrfltr: "new",
  kwdfltr: "nokwd",
  dayType: "day_off",
}

# 分析カテゴリ
set_action(params[:category], @cond)
# 使用端末
set_device_type(params[:devfltr], @cond)
# 来訪者
set_visitor_type(params[:usrfltr], @cond)
#　グラフ表示項目
@graphic_item  = (params[:metrics].presence || 'pageviews').to_sym

# CV種類
@cv_num = (@content.nil? ? params[:cv_num] : '1').to_i
# 絞り込みキーワードの指定
if params[:kwdfltr]
  narrow_tag = params[:kwdfltr][-1]
  params[:kwdfltr].slice!(-1);
  set_narrow_word(params[:kwdfltr], @cond, narrow_tag)
end
# 日付タイプを設定
@day_type = params[:dayType].presence || 'all_day'
Rails.logger.info("@cond setting is #{@cond}")
