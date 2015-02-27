FactoryGirl.define do
  factory :gaproject, class: Gaproject do
    id 1
    proj_owner_email "senk_example@senk-inc.co.jp"
    proj_owner_password "sen9_Example"
    api_key "AIzaSyCK0V0ly6c9kUBKLTIVcqR_zfnxoaBq5RQ"
  end

  factory :gaproject2, class: Gaproject do
    id 2
    proj_owner_email "senk_example2@senk-inc.co.jp"
    proj_owner_password "senq_Example2"
    api_key "AIzaSyAtLMcTWgtIuvwB6bmGg5m2x41ZFpyDAbM"
  end
end
