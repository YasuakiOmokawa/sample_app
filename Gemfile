source 'http://rubygems.org'
ruby '2.0.0'
#ruby-gemset=railstutorial_rails_4_0

gem 'rails', '4.0.5'
gem 'pg', '0.15.1'
gem 'bootstrap-sass', '2.3.2.0'
gem 'sprockets', '2.11.0'
gem 'bcrypt-ruby', '3.1.2'
gem 'faker', '1.1.2'
gem 'will_paginate', '3.0.4'
gem 'bootstrap-will_paginate', '0.0.9'
gem 'garb'
gem 'json', '1.8.0'
gem 'holiday_japan'
gem 'gon'
gem 'jquery-turbolinks'
gem 'sass-rails', '4.0.2'
gem 'uglifier', '2.1.1'
gem 'coffee-rails', '4.0.1'
gem 'jquery-rails', '3.0.4'
gem 'jquery-ui-rails', '4.2.1'
gem 'turbolinks', '1.1.1'
gem 'jbuilder', '1.0.2'
gem "daemons" # デプロイ先でデーモンとして動かすのに必要
gem 'spinjs-rails', '1.3'
gem 'newrelic_rpm'
# gem 'google-api-client' # oauth2認証に必要
# gem 'oauth2' # oauth2認証に必要
# gem 'parallel' # バブルチャート取得処理を並行化
# gem 'friendly_id' # URL表記をわかりやすくする
gem 'retryable' # APIコールのリトライを実行しやすくする
gem 'dalli' # memcache クライアント
gem 'tooltipster-rails' # ツールチップ（吹き出し）
gem 'jquery-hotkeys-rails' # ブラウザショートカットキーの操作用
gem 'historyjs-rails' # ブラウザの履歴情報を保持する
gem "heroku_backup_task", :git => "git://github.com/mataki/heroku_backup_task.git" # AWS S3 へDBバックアップをコピー

group :development, :test do
  gem 'rspec-rails', '2.13.1'
  gem 'guard-rspec', '2.5.0'
  gem 'spork-rails', '4.0.0'
  gem 'guard-spork', '1.5.0'
  gem 'childprocess', '0.3.6'
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'better_errors'
  gem 'pry-rescue'              # exception event handler
  gem 'hirb-unicode'            # hirb
  gem 'binding_of_caller'
  gem 'awesome_print' # オブジェクトの見やすさを改善
  gem 'hirb' # pry上でsql結果を整形
  gem 'wdm', '>= 0.1.0' # avoid polling for changes on windows
end

group :test do
  gem 'selenium-webdriver'
  gem 'capybara', '2.1.0'
  gem 'factory_girl_rails', '4.2.1'
  gem 'database_cleaner' # データベースが絡むテストには必要
  # gem 'capybara-webkit' # デフォルトのjavascript_driverを変更する場合
  # gem "launchy" # ブラウザ立ち上げ抑止 windowsでは 使用不可
  # gem 'headless' #webkit テスト時にブラウザを立ち上げさせない windows では使えない
end

group :doc do
  gem 'sdoc', '0.3.20', require: false
end

group :production do
  gem 'rails_12factor', '0.0.2'
  gem 'unicorn'
end
