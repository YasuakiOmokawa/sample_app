require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsServiceClass

  def self.create_class(name, met, dim = [])
    name = name.to_s
    self.class.const_set(name, Class.new do |klass|
      extend Garb::Model
      metrics met
      dimensions dim
    end)
  end

  class GapDataForGraph
      extend Garb::Model
      metrics :pageviews,
                    :sessions,
                    :pageviewsPerSession,
                    :avgSessionDuration,
                    :percentNewSessions,
                    :bounceRate
      dimensions :date
  end

  # class CVForGraphSkeleton
  #     extend Garb::Model
  #     metrics @goal_completions
  #     dimensions :date
  # end


  def GapRepeatDataForGraph
      extend Garb::Model
      metrics :sessions
      dimensions :date
  end

  # class NotGapDataForKitchen
  #     extend Garb::Model
  #     metrics :pageviews,
  #                   :sessions,
  #                   @goal_completions,
  #                   @goal_conversion_rate,
  #                   :bounceRate
  #     # dimensions :date
  # end

  class GapDataForKitchen
      extend Garb::Model
      metrics :pageviewsPerSession,
                    :avgSessionDuration,
                    :percentNewSessions
      # dimensions :date
  end

  class GapRepeatDataForKitchen
      extend Garb::Model
      metrics :sessions
      # dimensions :date
  end

  class FetchKeywordForSearch
      extend Garb::Model
      metrics :sessions,
                    :adsenseCTR,
                    :adsenseAdsClicks
      dimensions :keyword
  end

  class FetchKeywordForPages
      extend Garb::Model
      metrics :pageviews
      dimensions :pageTitle,
                          :pagePath
  end
end
