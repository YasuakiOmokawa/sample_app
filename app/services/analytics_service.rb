require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsService
  def load_profile(user_data)
    # f = File.open(File.join(Rails.root, 'app','services','conf.yml'))
    # f = File.open(File.join('app','services','conf.yml'))
    # conf_str = f.read
    # myconf = YAML.load(conf_str)

    #先月の初め
    # start_date = (1.month.ago Time.now).beginning_of_month
    #先月の終わり
    # end_date = (1.month.ago Time.now).end_of_month

    # セッションログイン
    Garb::Session.login(
        user_data.analytics_email,
        user_data.analytics_password
    )

    # プロファイル情報の取得
      profile = Garb::Management::Profile.all.detect { |p|
        p.web_property_id == user_data.property_id
        p.id == user_data.profile_id
      }
  end

  # 指標とディメンションをGarb::Modelをextendしたクラスに定義
  # class PageTitle
  #     extend Garb::Model
  #     metrics :pageviews
  #     dimensions :date
  # end

  # cond = {
  #     :start_date => start_date,
  #     :end_date   => end_date,
  #     # :filters    => { :page_path.contains => '^/items/' }
  # }

  # rs = PageTitle.results(profile, cond)
  # p rs
  # rs.each do |r|
  #     puts r.pageviews # ページビュー
  # end
end
