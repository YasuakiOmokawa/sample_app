require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsServiceClass

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

  class CVForGraphSkeleton
      extend Garb::Model
      metrics :goal1Completions
      dimensions :date
  end


  class GapRepeatDataForGraph
      extend Garb::Model
      metrics :sessions
      dimensions :date
  end

  class NotGapDataForKitchen
      extend Garb::Model
      metrics :pageviews,
                    :sessions,
                    :goal1Completions,
                    :goal1ConversionRate,
                    :bounceRate
      # dimensions :date
  end

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
