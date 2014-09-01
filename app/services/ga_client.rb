require 'google/api_client'

# google analytics api アクセストークンの取得プログラム

class GaClient
  def service_account_user(user_data)
    scope="https://www.googleapis.com/auth/analytics.readonly"
    client = Google::APIClient.new(
      :application_name => "tas",
      :application_version => "1.00"
    )
    ENV['SSL_CERT_FILE'] = File.join(Rails.root, %w{ app services data cert cacert.pem })

    tmp_key = user_data.gaproject.svc_acnt_key # テーブルから情報を取得
    email = user_data.gaproject.svc_acnt_email # テーブルから情報を取得
    key = OpenSSL::PKey::RSA.new(tmp_key)
    # key = Google::APIClient::PKCS12.load_key(File.join(%w{C: Users Yasuaki3 Downloads Analytics.p12}), "notasecret")

    service_account = Google::APIClient::JWTAsserter.new(email, scope, key)
    client.authorization = service_account.authorize
    oauth_client = OAuth2::Client.new("", "", {
      :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
      :token_url => 'https://accounts.google.com/o/oauth2/token'
    })
    token = OAuth2::AccessToken.new(oauth_client, client.authorization.access_token, expires_in: 1.hour)
    return token
  end
end
