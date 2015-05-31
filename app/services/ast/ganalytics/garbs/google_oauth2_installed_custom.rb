module Ast

  module Ganalytics

    module Garbs

      class GoogleOauth2InstalledCustom
        prepend GoogleOauth2Installed

        def initialize(gaproject)
          @gaproject = gaproject
        end

        # 環境変数を見ないように書き換え
        def credentials
          {
            method: 'OAuth2',
            oauth2_client_id: @gaproject[:oauth2_client_id],
            oauth2_client_secret: @gaproject[:oauth2_client_secret],
            oauth2_token: oauth2_token,
            oauth2_scope: @gaproject[:oauth2_scope],
            oauth2_redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
            oauth2_urls: {
              authorize_url: 'https://accounts.google.com/o/oauth2/auth',
              token_url: 'https://accounts.google.com/o/oauth2/token',
            },
          }
        end

        def access_token
          AccessToken.new(credentials).access_token
        end

        # To be used interactively
        def get_access_token
          Setup.new(credentials).get_access_token
        end

        private

          def oauth2_token
            {
              access_token: @gaproject[:oauth2_access_token],
              refresh_token: @gaproject[:oauth2_refresh_token],
              expires_at: @gaproject[:oauth2_expires_at].to_i
            }
          end
      end
    end
  end
end
