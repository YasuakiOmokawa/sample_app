FactoryGirl.define do
  factory :user, class: User do
    name "Michael Hartl"
    sequence(:email) { |n| "michael#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    admin true
  end

  factory :multiple_test_user, class: User do
    id 1
    name "Michael Hartl"
    sequence(:email) { |n| "michael#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    gaproperty_id "UA-36581569-1"
    gaprofile_id "66473324"
    gaproject_id 1
  end

  factory :multiple_test_user2, class: User do
    id 2
    name "Michael Hartl"
    sequence(:email) { |n| "michaesl#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    gaproperty_id "UA-36581569-1"
    gaprofile_id "66473324"
    gaproject_id 1
  end
end
