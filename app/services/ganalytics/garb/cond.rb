module Ganalytics

  module Garb

    class Cond

      def initialize(cond)
        @cond = cond
      end

      def cved_session(cv)
        @cond.merge( @cond[:filters] = { cv.to_sym.send(:gte) => 1 } )
      end

      def sort_favorite_for_calc
        @cond.merge({
          limit: 100,
          sort: :sessions.desc
          })
      end

      def sort_landing_for_calc
        @cond.merge({
          limit: 100,
          sort: :bounceRate.desc
          })
      end

      def sort_landing_for_skelton
        @cond.merge({
          limit: 5,
          sort: :bounceRate.desc
          })
      end

      def sort_favorite_for_skelton
        @cond.merge({
          limit: 5,
          sort: :sessions.desc
          })
      end
    end
    # gc = Cond.new(@cond)
  end
end
