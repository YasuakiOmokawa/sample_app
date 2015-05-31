require 'rubygems'
require 'garb'

module Ast

  module Ganalytics

    module Garbs

      class Session

        def initialize(params)
          @oauth2 = params.oauth2
          @user_data = params.user_data
        end

        # セッション取得
        def login
          session = Garb::Session.new
          session.access_token = @oauth2.access_token
          session
        end

        # プロファイル情報の取得
        def load_profile
          Garb::Management::Profile.all(login).detect { |p|
            p.web_property_id == @user_data.gaproperty_id
            p.id == @user_data.gaprofile_id
          }
        end

        # 設定されているゴール値の取得
        def get_goal
          # ゴール(CV)情報の取得
          goal = Garb::Management::Goal::for_profile(load_profile)

          goal.reduce({}) do |acum, item|
            j = JSON.load(item.to_json)
            acum[j['entry']['name']] = j['entry']['id']
            acum
          end
        end
      end
    end
  end
end
