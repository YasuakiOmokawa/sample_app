FactoryGirl.define do
  factory :user, class: User do
    name "Michael Hartl"
    sequence(:email) { |n| "michael#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    admin true
  end

  factory :senqinctool_user, class: User do
    # 関連(モデル名)を定義
    gaproject
    # 通常属性を定義
    id 1
    name "Michael Hartl"
    sequence(:email) { |n| "michael#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    gaproperty_id "UA-52923071-1"
    gaprofile_id "88709341"
  end

  factory :no_upload_user, class: User do
    # 関連を定義
    gaproject
    id 2
    name "Michael Hartl"
    sequence(:email) { |n| "michael#{n}@example.com" }
    password "12345678"
    password_confirmation "12345678"
    gaproperty_id "UA-36581569-1"
    gaprofile_id "66473324"
  end
end
