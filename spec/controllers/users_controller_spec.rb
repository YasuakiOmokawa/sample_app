require('rails_helper')

require 'holiday_japan'
require 'securerandom'
require "retryable"
require 'user_func'
require 'create_table'
require 'insert_table'
require 'update_table'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils, ExcelFunc

describe UsersController do
  before do
    require('pstore')
    out_file_path =  Rails.root.join('spec', 'fixtures', 'garb').to_s
    db = PStore.new(out_file_path)
    db.transaction{ |garb|
      @ga_profile = garb[:ga_profile]
      @ast_data = garb[:ast_data]
      @cved_data = garb[:cved_data]
      @fav_gap = garb[:fav_gap]
      @fav_for_skel = garb[:fav_for_skel]
      @land_for_skel = garb[:land_for_skel]
      @ga_result = garb[:ga_result]
      @cv_for_graph = garb[:cv_for_graph]
      @soc_source = garb[:soc_source]
      @soc_gap = garb[:soc_gap]
      @ref_source = garb[:ref_source]
      @ref_gap = garb[:ref_gap]
      @soc_session_rank = garb[:soc_session_rank]
      @soc_session_data = garb[:soc_session_data]
    }
    @cv_num = 1
    @data_for_graph_display = Hash.new{ |h,k| h[k] = {} }
    @day_type = 'day_off'
    @cv_txt = ('goal' + @cv_num.to_s + '_completions')
    @from = set_date_format('2014/12/1')
    @to = set_date_format('2014/12/1')
    @cond = { :start_date => @from, :end_date   => @to, :filters => {}, }
  end

  describe "is_not_uniq?" do
    it "配列データが一意でなければtrueを返すこと" do
      d = %w(1.0 2.0 2.0)
      expect(is_not_uniq?(d)).to eq(true)
    end

    it "配列データが一意であればtrueを返さないこと" do
      d = %w(1.0 1.0 1.0)
      expect(is_not_uniq?(d)).not_to eq(true)
    end
  end

  describe "@valids" do
    it "validコレクションのメトリクスを削除したとき、newに渡した引数データが変化しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.metricses.delete(:sessions) if valid.day_type == 'all_day'
        valid.metricses.delete(:pageviews) if valid.day_type == 'day_on'
        valid.metricses.delete(:users) if valid.day_type == 'day_off'
        expect(@metrics_snake_case_datas.size).not_to eq(valid.metricses.size)
      end
    end

    it "validコレクションのメトリクスを削除したとき、互いのデータに干渉しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.metricses.delete(:sessions) if valid.day_type == 'all_day'
        valid.metricses.delete(:pageviews) if valid.day_type == 'day_on'
        valid.metricses.delete(:users) if valid.day_type == 'day_off'
      end
      @valids.each do |valid|
        if valid.day_type == 'all_day'
          expect(valid.metricses.include?(:pageviews)).to eq(true)
        elsif valid.day_type == 'day_on'
          expect(valid.metricses.include?(:users)).to eq(true)
        else
          expect(valid.metricses.include?(:sessions)).to eq(true)
        end
      end
    end

    it "validコレクションの日付を削除したとき、newに渡した引数データが変化しないこと" do
      metrics = Metrics.new()
      @metrics_snake_case_datas = metrics.garb_result
      @valid_analyze_day_types = get_day_types
      @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create
      @valids.each do |valid|
        valid.day_type.delete('all_day') if valid.day_type == 'all_day'
        expect(@valid_analyze_day_types.include?('all_day')).to eq(true)
      end
    end
  end

  describe "UserFunc" do

    describe "validate_cv" do

      it "validate対象データが呼ばれること" do
        expect(@ast_data[0].date).to eq('20141101')
      end

      it "CVバリデートし、全ての日付タイプが分析対象として残ること" do
        @valid_analyze_day_types = get_day_types
        validate_cv
        expect(@valid_analyze_day_types.size).to eq(3)
      end
    end

    describe "validate_metrics" do

      it "指標バリデートし、全日付タイプ全項目が分析対象として残ること" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result
        @valid_analyze_day_types = get_day_types
        @valids = ValidAnalyzeMaterial.new(@valid_analyze_day_types, @metrics_snake_case_datas).create

        validate_metrics
        expect(@valids.map{|item| item.metricses.size}.sum).to eq(24)
      end

      it "異常指標が除外されること: 値の種類が１つしかない指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        data = %w(1.0 1.0) #異常用コード
        delete_uniq_metrics(data, :pageviews, @metrics_snake_case_datas)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end

      it "異常指標が除外されること: CVと指標の一意な組み合わせが少ない指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        cves = %w(1.0 1.0) #異常用コード
        data = %w(1.0 1.0) #異常用コード
        delete_invalid_metrics_multiple(data, :pageviews, @metrics_snake_case_datas, cves)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end

      it "異常指標が除外されること: ゼロが多すぎる指標" do
        metrics = Metrics.new()
        @metrics_snake_case_datas = metrics.garb_result

        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(true)
        data = [1, 2, 0, 0, 0, 0, 0, 0, 0] #異常用コード
        delete_too_much_zero_metrics(data, :pageviews, @metrics_snake_case_datas)
        expect(@metrics_snake_case_datas.include?(:pageviews)).to eq(false)
      end
    end
  end

  describe "分析の開始" do
    before do
      metrics = Metrics.new()
      @metrics_for_graph_merge = metrics.jp_caption
      @metrics_snake_case_datas = metrics.garb_result
      @bubble_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, 'all_day')
    end

    it "バブルチャート表示データを正常に算出できること" do
      expect(@bubble_datas).to be_truthy
    end

    it "日本語名をバブルチャート表示データへ付与できること" do
      d_hsh = metrics_day_type_jp_caption('all_day', @metrics_for_graph_merge)
      home_graph_data = concat_data_for_graph(@bubble_datas, d_hsh)

      expect(home_graph_data[:pageviews][:jp_caption]).to eq('PV数')
      expect(home_graph_data[:pageviews_per_session][:jp_caption]).to eq('平均PV数')
      expect(home_graph_data[:sessions][:jp_caption]).to eq('セッション')
      expect(home_graph_data[:avg_session_duration][:jp_caption]).to eq('平均滞在時間')
      expect(home_graph_data[:bounce_rate][:jp_caption]).to eq('直帰率')
      expect(home_graph_data[:percent_new_sessions][:jp_caption]).to eq('新規ユーザー')
      expect(home_graph_data[:users][:jp_caption]).to eq('ユーザー')
      expect(home_graph_data[:repeat_rate][:jp_caption]).to eq('リピーター')
    end
  end

  describe "create_common_table" do
    before do
      metrics = Metrics.new()
      @metrics_for_graph_merge = metrics.jp_caption
      @metrics_snake_case_datas = metrics.garb_result
      @bubble_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, 'all_day')
      @day_type = "all_day"
      @graphic_item = :pageviews
    end

    it "人気ページ用CVデータが読めること" do
      expect(@cved_data).to be_truthy
    end

    it "人気ページ用GAPデータが読めること" do
      expect(@fav_gap).to be_truthy
    end

    it "人気ページ用スケルトンデータが読めること" do
      expect(@fav_for_skel).to be_truthy
    end

    it "ランディングページ用データが読めること" do
      expect(@land_for_skel).to be_truthy
    end

    it "全セッション用データが読めること" do
      expect(@ga_result).to be_truthy
    end

    it "グラフ用CVデータが読めること" do
      expect(@cv_for_graph).to be_truthy
    end

    it "ソーシャルランキングデータが読めること" do
      expect(@soc_session_rank).to be_truthy
    end

    it "リファレンスソースデータが読めること" do
      expect(@ref_source).to be_truthy
    end

    it "ソーシャルソースデータが読めること" do
      expect(@soc_session_data).to be_truthy
    end

    it "リファレンスギャップデータが読めること" do
      expect(@ref_gap).to be_truthy
    end

    it "グラフデータテーブルへ表示する日本語指標値を取得できること" do
      @desire_caption = @metrics_for_graph_merge[@graphic_item][:jp_caption]
      expect(@desire_caption).to eq("PV数")
    end

    it "目標値が算出できること" do
      desire_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, @day_type)
      calc_desire_datas(desire_datas)
      expect(desire_datas[@graphic_item][:desire]).to be_truthy
    end

    it "日本語キャプションが追加できること" do
      d_hsh = metrics_day_type_jp_caption(@day_type, @metrics_for_graph_merge)
      desire_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, @day_type)
      @details_desire_datas = concat_data_for_graph(desire_datas, d_hsh)
      expect(@details_desire_datas[@graphic_item][:jp_caption]).to eq("PV数")
    end

    it "年月のグルーピングを作成できること" do
      ym = group_by_year_and_month(@ast_data)
      expect(ym.size).to eq(2)
    end

    it "グラフ表示プログラムへ渡すデータを作成できること" do
      create_data_for_graph_display(@data_for_graph_display, @ast_data, @graphic_item, @cv_num)
      @data_for_graph_display = create_monthly_summary_data_for_graph_display(
        @data_for_graph_display, group_by_year_and_month(@ast_data),
        @graphic_item) if chk_monthly?(nil) == true
      expect(@data_for_graph_display).to be_truthy
    end

    it "年月のグルーピングを作成できていれば、サマリデータを返すこと" do
      create_data_for_graph_display(@data_for_graph_display, @ast_data, @graphic_item, @cv_num)
      @data_for_graph_display = create_monthly_summary_data_for_graph_display(
        @data_for_graph_display, group_by_year_and_month(@ast_data),
        @graphic_item) if chk_monthly?(group_by_year_and_month(@ast_data)) == true
      expect(@data_for_graph_display).to be_truthy
    end

    it "グラフテーブルへ渡すデータを作成できること" do
      @data_for_graph_table = Hash.new{ |h,k| h[k] = {} }
      create_data_for_graph_display(@data_for_graph_table, @ast_data, @graphic_item, @cv_num)
      expect(@data_for_graph_table).to be_truthy
    end

    it "目標値データのフォーマット変更ができること" do
      d_hsh = metrics_day_type_jp_caption(@day_type, @metrics_for_graph_merge)
      desire_datas = generate_graph_data(@ast_data, @metrics_snake_case_datas, @day_type)
      calc_desire_datas(desire_datas) # 目標値の算出
      @details_desire_datas = concat_data_for_graph(desire_datas, d_hsh)
      @details_desire_datas.each do |k, v|
        change_format_for_desire(@details_desire_datas[k],
          check_format_graph(k).to_s, v)
      end
      expect(@details_desire_datas[:pageviews].values.to_s).to_not match('%')
      expect(@details_desire_datas[:pageviews].values.to_s).to_not match(':')
      expect(@details_desire_datas[:repeat_rate].values.to_s).to match('%')
      expect(@details_desire_datas[:avg_session_duration].values.to_s).to match(':')
    end

    it "グラフテーブルのフォーマットが変更できること" do
      @data_for_graph_table = Hash.new{ |h,k| h[k] = {} }
      create_data_for_graph_display(@data_for_graph_table, @ast_data, @graphic_item, @cv_num)
      @data_for_graph_table.each do |k, v|
        change_format_for_graph_table(@data_for_graph_table[k], check_format_graph(@graphic_item), v[0] )
      end
      expect(@data_for_graph_table.to_s).to_not match(':')
      expect(@data_for_graph_table.to_s).to_not match('%')
    end

    it "人気ページテーブルデータのgoodとbadの和がgapと同値になること" do
      #事前処理
      tmp_all_session = @ga_result.results.first.sessions.to_i if @ga_result.total_results > 0
      all_session = guard_for_zero_division(tmp_all_session)

      @favorite_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      cved_session = @cved_data.map{|t| t.sessions.to_f}.sum
      not_cved_session = all_session - cved_session
      create_skeleton_favorite_table(@fav_for_skel, @favorite_table)
      put_favorite_table_for_skelton(@fav_gap, @favorite_table)
      calc_percent_for_favorite_table(cved_session, @favorite_table, :good)
      calc_percent_for_favorite_table(not_cved_session, @favorite_table, :bad)
      calc_gap_for_favorite(@favorite_table)

      @favorite_table.values.each { |v| expect(v[:good] + v[:bad] ).to eq(v[:gap].abs) }
    end

    it "ランディングページテーブルが加工できること" do
      @landing_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      put_landing_table(@land_for_skel, @landing_table)
      expect(@landing_table).to be_truthy
    end
  end

  describe 'special_parameter_per_action' do
    it "Garbのデータ構造を操作するために、属性の書式を変更できること" do
      expect(to_garb_attr(:socialNetwork)).to eq(:social_network)
    end
  end

  describe "referral" do
    before do
      @special = :source
      @special_for_garb = to_garb_attr(@special)
      @sample_reduced_data = reduce_with_kwd(@soc_session_data,
        "(not set)", @special_for_garb)
      @sample_changed_kwds = change_to_garb_kwds(@soc_session_rank,
        @special_for_garb)
      @in_table = @soc_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      @categories = []
      @res_table = {
        "(not set)" => {
                      :corr => 0.2,
                 :corr_sign => "plus",
                      :vari => 0.1,
            :metrics_stddev => 7.7,
               :metrics_avg => 84.2
        },
        "(set)" => {
                      :corr => "-",
                 :corr_sign => "plus",
                      :vari => 0.1,
            :metrics_stddev => 7.7,
               :metrics_avg => 84.2
        }
      }
    end

    describe "データ取得" do

      it "ランクデータを取得できること" do
        expect(get_session_rank(@special)).to be_truthy
      end

      it "セッションデータを取得できること" do
        expect(get_session_data(@special)).to be_truthy
      end
    end
  end

  describe "social" do
    before do
      @special = :socialNetwork
      @special_for_garb = to_garb_attr(@special)
      @sample_reduced_data = reduce_with_kwd(@soc_session_data,
        "(not set)", @special_for_garb)
      @sample_changed_kwds = change_to_garb_kwds(@soc_session_rank,
        @special_for_garb)
      @in_table = @soc_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
      @categories = []
      @res_table = {
        "(not set)" => {
                      :corr => 0.2,
                 :corr_sign => "plus",
                      :vari => 0.1,
            :metrics_stddev => 7.7,
               :metrics_avg => 84.2
        },
        "(set)" => {
                      :corr => "-",
                 :corr_sign => "plus",
                      :vari => 0.1,
            :metrics_stddev => 7.7,
               :metrics_avg => 84.2
        }
      }

    end

    describe "データ取得" do

      it "ランクデータを取得できること" do
        expect(get_session_rank(@special)).to be_truthy
      end

      it "セッションデータを取得できること" do
        expect(get_session_data(@special)).to be_truthy
      end
    end

    context "正常にデータが絞り込まれた場合" do

      it "Garbのランキングデータをキーワードデータに修正できること" do
        expect(@sample_changed_kwds).to be_truthy
      end

      it "算出した相関データの上位３つを絞り込めること" do
        expect(head_special(@res_table, 3)).to be_truthy
      end

      it "絞り込みリストボックスへ表示するための配列を作成できること" do
        @in_table = head_special(@res_table, 3)
        create_listbox_categories('l')
        expect(@categories).to be_truthy
      end
    end

    context "データが絞り込まれなかった場合" do

      it "相関算出に失敗すること" do
      @sample_not_reduced_data = reduce_with_kwd(@soc_session_data,
        "(set)", @special_for_garb) # -> nil
        soc_table = Hash.new { |h,k| h[k] = {} } #多次元ハッシュを作れるように宣言
        soc_table["(set)"] = generate_graph_data(
          @sample_not_reduced_data, [:sessions], 'all_day')
        expect(soc_table["(set)"]).not_to be_truthy
      end
    end
  end
end
