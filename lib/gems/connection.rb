require 'faraday_middleware'

module Gems
  module Connection
    private

    def connection
      options = {
        :headers => {'Accept' => 'application/json'},
        :ssl => {:verify => false},
        :url => 'https://rubygems.org',
      }

      Faraday.new(options) do |connection|
        connection.use Faraday::Request::UrlEncoded
        connection.use Faraday::Response::RaiseError
        connection.use Faraday::Response::Mashify
        connection.use Faraday::Response::ParseJson
        connection.adapter(Faraday.default_adapter)
      end
    end
  end
end
