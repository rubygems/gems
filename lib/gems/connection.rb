require 'faraday_middleware'

module Gems
  module Connection
    private

    def connection(format=:json)
      options = {
        :ssl => {:verify => false},
        :url => 'https://rubygems.org',
      }

      Faraday.new(options) do |connection|
        connection.use Faraday::Request::UrlEncoded
        connection.use Faraday::Response::RaiseError
        connection.use Faraday::Response::Mashify
        connection.use Faraday::Response::ParseXml if :xml == format
        connection.use Faraday::Response::ParseJson if :json == format
        connection.use Faraday::Response::ParseMarshal if :marshal == format
        connection.adapter Faraday.default_adapter
      end
    end
  end
end
