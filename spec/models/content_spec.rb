require('rails_helper')

describe Content do

  it "データが3行以上ないとエラーになること" do
    csv_path_1 =  Rails.root.join('spec', 'fixtures', '1.tsv').to_s
    arr_of_arrs_1 = CSV.read(csv_path_1, {col_sep: "\t"})
    content = Content.new(upload_file: arr_of_arrs_1)
    content.valid?
    expect(content.errors[:upload_file]).to include('データ数は3行以上にしてください')
  end
end
