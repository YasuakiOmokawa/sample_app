require('rails_helper')

describe Metrics do
  it "garb用パラメータ配列の数が7つであること" do
    metrics = Metrics.new()
    expect(metrics.garb_parameter.size).to eq 7
  end

  it "garb用パラメータ配列の最初の要素が:pageviewsであること" do
    metrics = Metrics.new()
    expect(metrics.garb_parameter[0]).to eq :pageviews
  end

  it "ロワースネークケースで文字列を返却できること" do
    metrics = Metrics.new()
    expect(metrics.garb_result[1]).to eq :pageviews_per_session
  end

  it "garb結果操作用配列の最後の要素が:repeat_rateであること" do
    metrics = Metrics.new()
    expect(metrics.garb_result[7]).to eq :repeat_rate
  end

  it "日本語表記配列の:pageviewsキーに対応する文字列がPV数であること" do
    m = Metrics.new()
    expect(m.jp_caption[:pageviews][:jp_caption]).to eq 'PV数'
  end

  it "日本語表記配列の:repeat_rateキーに対応する文字列が再訪問者でないこと" do
    m = Metrics.new()
    expect(m.jp_caption[:repeat_rate][:jp_caption]).not_to eq '再訪問者'
  end

end
