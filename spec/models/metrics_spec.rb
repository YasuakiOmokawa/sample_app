require 'spec_helper'

describe Metrics do
  # pending "add some examples to (or delete) #{__FILE__}"
  it "@gaの:pageviewsキーに対応する値がPV数であること" do
    metrics = Metrics.new()
    expect(metrics.garb_parameter[:pageviews]).to eq 'PV数'
  end

  it "@gaの:pageviewsキーに対応する値がPV数であること" do
    metrics = Metrics.new()
    expect(metrics.garb_parameter[:pageviews]).to eq 'PV数'
  end
end
