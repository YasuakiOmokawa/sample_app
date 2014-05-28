require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsService
  def load_profile(user_data)

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
end
