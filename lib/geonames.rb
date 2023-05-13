require "geonames/version"
require "geonames/blocks"
require "geonames/railtie" if defined?(Rails)

module Geonames
  def self.search(query, options = {})
    ret = nil

    type = options[:type] || :auto
    begin
      case type
      when :auto # return an array of features
        # city name
        ret = Geonames::City.search(query)
        # alternate name
        ret = Geonames::AlternateName.search(query).map { |alternate| alternate.feature }.compact  if ret.blank?
        # admin1
        ret = Geonames::Admin1.search(query) if ret.blank?
        # admin2
        ret = Geonames::Admin2.search(query) if ret.blank?
        # feature
        ret = Geonames::Feature.search(query) if ret.blank?
        # country
        ret = Geonames::Country.search(query) if ret.blank?
      else # country, or specific type
        model = "geonames/#{type.to_s}".camelcase.constantize
        ret = model.search(query)
      end
    rescue NameError => e
      raise $!, "Unknown type for Geonames, #{$!}", $!.backtrace
    end


    ret
  end
end
