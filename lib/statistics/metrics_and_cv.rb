module Statistics
  class MetricsAndCV
    MetricsAndCV = Struct.new(:metrics, :cv)

    def initialize(arr)
      @arr = arr
    end

    def create
      @arr.reduce([]) do |datas, data|
        datas << MetricsAndCV.new(data[0], data[1])
      end
    end
  end
end
