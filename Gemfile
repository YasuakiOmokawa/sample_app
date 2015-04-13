source 'http://rubygems.org'
ruby '2.2.1'
#ruby-gemset=railstutorial_rails_4_0

# postgresインストール前実行コマンド
# bundle config build.pg --with-pg-config=/usr/pgsql-9.3/bin/pg_config --with-pg-lib=/usr/pgsql-9.3/lib

# vagrant環境へインストール
# bundle install --path /home/vagrant/bundles/sample_app

gem 'rails', '4.1.1'
gem 'pg', '0.15.1'
gem 'bootstrap-sass', '2.3.2.0'
gem 'sprockets', '2.11.0'
gem 'bcrypt-ruby', '3.1.2'
gem 'will_paginate', '3.0.4'
gem 'bootstrap-will_paginate', '0.0.9'
gem 'garb'
gem 'json', '1.8.2'
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
gem 'parallel' # バブルチャート取得処理を並行化
gem 'retryable' # APIコールのリトライを実行しやすくする
gem 'dalli' # memcache クライアント
gem 'tooltipster-rails' # ツールチップ（吹き出し）
gem 'jquery-hotkeys-rails' # ブラウザショートカットキーの操作用
gem 'historyjs-rails' # ブラウザの履歴情報を保持する
gem "heroku_backup_task", :git => "git://github.com/mataki/heroku_backup_task.git" # AWS S3 へDBバックアップをコピー
gem 'airbrake' # Errbit通知用
gem 'therubyracer', :platforms => :ruby # javascriptランタイム
gem 'unicorn'


group :development, :test do
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'childprocess'
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
  # gem 'wdm', '>= 0.1.0' # avoid polling for changes on windows
end

group :test do
  gem "faker", "~> 1.4.3"
  gem "capybara", "~> 2.4.3"
  gem "database_cleaner", "~> 1.3.0"
  gem "launchy", "~> 2.4.2"
  gem "selenium-webdriver", "~> 2.43.0"
  # gem 'capybara-webkit' # デフォルトのjavascript_driverを変更する場合
  gem 'headless' #webkit テスト時にブラウザを立ち上げさせない windows では使えない
end

group :doc do
  gem 'sdoc', '0.3.20', require: false
end

group :production do
  gem 'rails_12factor', '0.0.2'
end
