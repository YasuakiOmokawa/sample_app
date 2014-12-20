module Ganalytics

  module Garb

    class Cond

      attr_reader :res

      def initialize(cnd, cv)
        @res = {}
        @cv = cv
        @res[:filters] = cnd[:filters].dup
        @res[:start_date] = cnd[:start_date].dup
        @res[:end_date] = cnd[:end_date].dup
      end

      def cved!
        @res[:filters].merge!( { @cv.to_sym.send(:gte) => 1 } )
        self
      end

      def limit!(n)
        @res.merge!({limit: n})
        self
      end

      def sort_desc!(k)
        @res.merge!({
          sort: k.desc
          })
        self
      end
    end
    # Ganalytics::Garb::Cond.new(@cond, @cv_txt).limit!(10).sort_desc!(:sessions).res
  end
end
