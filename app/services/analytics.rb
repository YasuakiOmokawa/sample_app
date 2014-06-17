require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class Analytics

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

  def GapRepeatDataForGraph
      extend Garb::Model
      metrics :sessions
      dimensions :date
  end

  class CommonForGap
      extend Garb::Model
      metrics :pageviewsPerSession,
                    :avgSessionDuration,
                    :percentNewSessions
  end

  class CommonRepeatForGap
      extend Garb::Model
      metrics :sessions
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
