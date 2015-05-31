require 'rubygems'
require 'garb'

module Ast

  module Ganalytics

    module Garbs

      class Session

        # セッションログイン
        def login
          session = Garb::Session.new
          session.access_token = GoogleOauth2Installed.access_token
          session
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
    end
  end
end
