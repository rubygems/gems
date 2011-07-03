require 'faraday'

module Gems
  module Connection
    def connection(content_length=nil, content_type=nil)
      options = {
        :headers => {
          :user_agent => user_agent,
        },
        :ssl => {:verify => false},
        :url => host,
      }

      options[:headers].merge!({:content_length => content_length}) if content_length
      options[:headers].merge!({:content_type => content_type}) if content_type
      options[:headers].merge!({:authorization => key}) if key

      connection = Faraday.new(options) do |connection|
        connection.use Faraday::Request::UrlEncoded unless content_type
        connection.use Faraday::Response::RaiseError
        connection.adapter Faraday.default_adapter
      end
      connection.basic_auth username, password if username && password
      connection
    end
  end
end
