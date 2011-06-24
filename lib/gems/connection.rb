require 'faraday_middleware'

module Gems
  module Connection
    def connection(format=format)
      options = {
        :headers => {
          'User-Agent' => user_agent,
        },
        :ssl => {:verify => false},
        :url => 'https://rubygems.org',
      }

      Faraday.new(options) do |connection|
        connection.use Faraday::Request::UrlEncoded
        connection.use Faraday::Response::RaiseError
        connection.use Faraday::Response::Mashify
        case format.to_s.downcase
        when 'json'
          connection.use Faraday::Response::ParseJson
        when 'marshal'
          connection.use Faraday::Response::ParseMarshal
        when 'xml'
          connection.use Faraday::Response::ParseXml
        end
        connection.adapter Faraday.default_adapter
      end
    end
  end
end
