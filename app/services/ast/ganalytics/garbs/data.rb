require 'garb'
require 'active_support/time'

module Ast

  module Ganalytics

    module Garbs

      class Data

        def self.create_class(name, met, dim = [])
          name = name.to_s + SecureRandom.hex(4).to_s
          self.class.const_set(name, Class.new do |klass|
            extend Garb::Model
            metrics met
            dimensions dim
          end)
        end

        class FetchKeywordForLanding
          extend Garb::Model
          metrics :bounceRate,
                        :sessions,
                        :avgSessionDuration
          dimensions :landingPagePath,
                            :pageTitle
        end

        class FetchKeywordForPages
            extend Garb::Model
            metrics :sessions
            dimensions :pageTitle,
                                :pagePath
        end
      end
    end
  end
end
