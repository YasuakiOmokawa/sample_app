namespace :db do
  desc "Fill database with sample admin data"
  task populate: :environment do
    User.create!(name: "拝みん",
                 email: "googleanalytics@senk-inc.co.jp",
                 password: "11111111",
                 password_confirmation: "11111111",
                 admin: false,
                 property_id: 'UA-45744185-2',
                 profile_id: '79083540',
                 analytics_email: 'googleanalytics@senk-inc.co.jp',
                 analytics_password: 'googleAnalytics',
                 apikey: '')
  end
end
