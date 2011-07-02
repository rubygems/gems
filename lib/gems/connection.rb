require 'faraday_middleware'

module Gems
  module Connection
    def connection(format=format)
      options = {
        :headers => {
          :user_agent => user_agent,
        },
        :ssl => {:verify => false},
        :url => 'https://rubygems.org',
      }

      options[:headers].merge!({:authorization => key}) if key

      connection = Faraday.new(options) do |connection|
        connection.use Faraday::Request::UrlEncoded
        connection.use Faraday::Response::Mashify
        case format.to_s.downcase
        when 'json'
          connection.use Faraday::Response::ParseJson
        when 'marshal'
          connection.use Faraday::Response::ParseMarshal
        when 'xml'
          connection.use Faraday::Response::ParseXml
        when 'yaml'
          connection.use Faraday::Response::ParseYaml
        end
        connection.use Faraday::Response::RaiseError
        connection.adapter Faraday.default_adapter
      end
      connection.basic_auth username, password if username && password
      connection
    end
  end
end
