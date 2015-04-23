source 'http://rubygems.org'
ruby '2.2.1'
#ruby-gemset=railstutorial_rails_4_0

# postgresインストール前実行コマンド
# bundle config build.pg --with-pg-config=/usr/pgsql-9.3/bin/pg_config --with-pg-lib=/usr/pgsql-9.3/lib

# vagrant環境へインストール
# bundle install --path /home/vagrant/bundles/sample_app

gem 'rails', '4.2.1'
gem 'pg'
gem 'bootstrap-sass', '3.3.4.1'
gem 'sprockets', '3.0.0'
gem 'bcrypt-ruby'
gem 'bcrypt'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'garb'
gem 'json'
gem 'holiday_japan'
gem 'gon'
gem 'jquery-turbolinks'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 5.0.0'
gem 'turbolinks'
gem 'jbuilder'
gem "daemons" # デプロイ先でデーモンとして動かすのに必要
gem 'spinjs-rails', '1.3.0'
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
  gem 'web-console', '~> 2.0' # デフォルトエラーページ用のデバッギングツール　Rails 4.2より
end

group :test do
  gem "faker", "~> 1.4.3"
  gem "capybara", "~> 2.4.3"
  gem "database_cleaner", "~> 1.3.0"
  gem "launchy", "~> 2.4.2"
  gem 'capybara-webkit', "~> 1.5.0" # デフォルトのjavascript_driverを変更する場合
  gem "poltergeist", "~> 1.6.0"
end

group :doc do
  gem 'sdoc', '0.3.20', require: false
end

group :production do
  gem 'rails_12factor', '0.0.2'
end


