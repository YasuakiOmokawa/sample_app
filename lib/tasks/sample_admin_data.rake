namespace :db do
  desc "Fill database with sample admin data"
  task populate: :environment do
    User.create!(name: "サンプル会社",
                 email: "example@example.jp",
                 password: "foobird",
                 password_confirmation: "foobird",
                 admin: true,
                 property_id: 'UA-36581569-1',
                 profile_id: '66473324',
                 analytics_email: 'example@example.jp',
                 analytics_password: 'foobird')
  end
end
