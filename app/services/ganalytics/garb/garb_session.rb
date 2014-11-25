require 'rubygems'
require 'garb'

class GarbSession

  # セッションログイン
  def login(user_data)

    session = Garb::Session.new

    # apikeyの投入
    session.api_key = user_data.gaproject.api_key

    # Single User Login
    session.login(
        user_data.gaproject.proj_owner_email,
        user_data.gaproject.proj_owner_password
    )

    return session
  end

  # セッションログイン(並列処理用)
  def login_multi(user_data, mlt_id)

    session = Garb::Session.new

    # gaprojectの指定
    gaproject = Gaproject.find(mlt_id.to_i)

    # apikeyの投入
    session.api_key = gaproject.api_key

    # Single User Login
    session.login(
        gaproject.proj_owner_email,
        gaproject.proj_owner_password
    )

    return session
  end

  # プロファイルのロード
  def load_profile(session, user_data)

    # プロファイル情報の取得
    profile = Garb::Management::Profile.all(session).detect { |p|
      p.web_property_id == user_data.gaproperty_id
      p.id == user_data.gaprofile_id
    }

    return profile
  end

  # 設定されているゴール値の取得
  def get_goal(profile)

    # リターン用ハッシュ
    hsh = {}

    # ゴール(CV)情報の取得
    goal = Garb::Management::Goal::for_profile(profile)

    goal.each do |t|
      jsn = t.to_json
      jload = JSON.load(jsn)
      k = jload['entry']['name']
      v = jload['entry']['id']
      hsh[k] = v
    end

    return hsh
  end
end
