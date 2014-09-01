require 'rubygems'
require 'garb'

class AnalyticsService
  def load_profile(user_data)

    session = Garb::Session.new

    # apikeyの投入
    session.api_key = user_data.gaproject.api_key

    # Single User Login
    session.login(
        user_data.gaproject.proj_owner_email,
        user_data.gaproject.proj_owner_password
    )

    # プロファイル情報の取得
      profile = Garb::Management::Profile.all(session).detect { |p|
        p.web_property_id == user_data.gaproperty_id
        p.id == user_data.gaprofile_id
      }
      return profile
  end
end
