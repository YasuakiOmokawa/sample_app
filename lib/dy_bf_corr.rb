class DyBfCorr
  Properties = %i(dy gp_dy cv_dy dt_dy date)
  Properties.each do |prop|
    attr_accessor prop
  end

  def initialize(hash = {})
    hash.each do |key, value|
      if Properties.member? key.to_sym
        self.send((key.to_s + '=').to_s, value)
      end
    end
  end
end
