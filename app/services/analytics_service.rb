require 'rubygems'
require 'garb'

class AnalyticsService
  def load_profile(user_data)

    # セッションログイン
    Garb::Session.api_key = user_data.apikey
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
