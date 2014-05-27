require 'rubygems'
require 'garb'
require 'uri'
require 'active_support/time'
require 'yaml'

class AnalyticsServiceClass

  class PageTitle
      extend Garb::Model
      metrics :pageviews
      dimensions :date
  end
end
