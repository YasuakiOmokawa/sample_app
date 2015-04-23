# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require('factory_girl')
require 'capybara/rails'
require 'capybara/rspec'
# require 'database_cleaner'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist


# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

LAUNCHY_DEBUG=true

RSpec.configure do |config|
  config.before(:all) do
    FactoryGirl.reload # これがないとfactoryの変更が反映されません
  end
  # config.filter_run focus: true

  # capybara のview render を有効化する
  config.render_views

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Include Factory Girl syntax to simplify calls to factories
  config.include FactoryGirl::Syntax::Methods

  # Capybara の文法を使う
  config.include Capybara::DSL

  # Include custom login macros
  config.include LoginMacros

  # RSpecでroutesのpathを指定するために設定
  config.include Rails.application.routes.url_helpers

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true
  # 追加箇所 trueからfalseにする
   config.use_transactional_fixtures = false

  # Add Begin
  # suite: RSpecコマンドでテストを実行する単位
  # all:  各テストファイル(xxx_spec.rb)単位
  # each: 各テストケース(it)単位
  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation  # テスト開始時にDBをクリーンにする
  end

  # js以外のテスト時は通常のtransactionでデータを削除する
  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
  end

  # jsのテスト時はtruncationで削除する
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:all) do
    DatabaseCleaner.clean_with :truncation # all時にDBをクリーンにする
  end
  # Add End

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end
