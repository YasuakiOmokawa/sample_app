# Read about factories at https://github.com/thoughtbot/factory_girl
require('csv')

FactoryGirl.define do
  arr_of_arrs_zero = CSV.read(Rails.root.join('spec',
    'fixtures', '1.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_valid = CSV.read(Rails.root.join('spec',
    'fixtures', '4.tsv').to_s, {col_sep: "\t"})

  factory :valid_content, class: Content do
    upload_file arr_of_arrs_valid
    upload_file_name 'valid_file'
    user_id 1
  end

  factory :zero_content, class: Content do
    upload_file arr_of_arrs_zero
    user_id 2
  end
end
