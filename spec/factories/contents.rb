# Read about factories at https://github.com/thoughtbot/factory_girl
require('csv')

FactoryGirl.define do
  arr_of_arrs_zero = CSV.read(Rails.root.join('spec',
    'fixtures', '1.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_valid = CSV.read(Rails.root.join('spec',
    'fixtures', 'same_as_ast_data.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_invalid_header = CSV.read(Rails.root.join('spec',
    'fixtures', '3.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_unmatch = CSV.read(Rails.root.join('spec',
    'fixtures', '5.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_invalid_date_format = CSV.read(Rails.root.join('spec',
    'fixtures', '8.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_invalid_from_to = CSV.read(Rails.root.join('spec',
    'fixtures', '7.tsv').to_s, {col_sep: "\t"})
  arr_of_arrs_invalid_from_date = CSV.read(Rails.root.join('spec',
    'fixtures', 'invalid_from.tsv').to_s, {col_sep: "\t"})

  factory :valid_content, class: Content do
    upload_file arr_of_arrs_valid
    upload_file_name 'valid_file'
    user_id 1
  end

  factory :zero_content, class: Content do
    upload_file arr_of_arrs_zero
    user_id 2
  end

  factory :invalid_header_content, class: Content do
    upload_file arr_of_arrs_invalid_header
    user_id 3
  end

  factory :invalid_unmatch_content, class: Content do
    upload_file arr_of_arrs_unmatch
    user_id 4
  end

  factory :invalid_date_format_content, class: Content do
    upload_file arr_of_arrs_invalid_date_format
    user_id 5
  end

  factory :invalid_from_to_content, class: Content do
    upload_file arr_of_arrs_invalid_from_to
    user_id 6
  end

  factory :invalid_from_date_content, class: Content do
    upload_file arr_of_arrs_invalid_from_date
    user_id 7
  end
end
