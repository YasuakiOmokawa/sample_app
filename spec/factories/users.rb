FactoryGirl.define do
  factory :user, class: User do
    name "Michael Hartl"
    email "michael@example.com"
    password "12345678"
    password_confirmation "12345678"
    admin true
  end
end
