require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsServiceClass

  class NotGapDataForKitchen
      extend Garb::Model
      metrics :pageviews,
                    :sessions,
                    :goal1Completions,
                    :goal1ConversionRate,
                    :bounceRate
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
