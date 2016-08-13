require 'httpi'
require 'rubygems'

module Gems
  module Request
    def delete(path, data = {}, content_type = 'application/x-www-form-urlencoded', request_host = host)
      request(:delete, path, data, content_type, request_host)
    end

    def get(path, data = {}, content_type = 'application/x-www-form-urlencoded', request_host = host)
      request(:get, path, data, content_type, request_host)
    end

    def post(path, data = {}, content_type = 'application/x-www-form-urlencoded', request_host = host)
      request(:post, path, data, content_type, request_host)
    end

    def put(path, data = {}, content_type = 'application/x-www-form-urlencoded', request_host = host)
      request(:put, path, data, content_type, request_host)
    end

  private

    def request(method, path, data, content_type, request_host = host) # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, ParameterLists, PerceivedComplexity
      uri = URI.parse [request_host, path].join
      @connection = HTTPI::Request.new uri.to_s
      @connection.query = data if [:delete, :get].include? method
      @connection.headers = {'Connection' => 'keep-alive',
                             'Keep-Alive' => '30',
                             'User-Agent' => user_agent,
                             'content-type' => content_type}
      @connection.headers['Authorization'] = key if key
      @connection.auth.basic(username, password) if username && password
      case content_type
      when 'application/x-www-form-urlencoded'
        @connection.body = data if [:post, :put].include? method
      else
        @connection.body = data
        @connection.headers['content-length'] = data.size.to_s
      end
      proxy = uri.find_proxy
      @connection.proxy = proxy if proxy
      @connection.auth.ssl.verify_mode = :none if uri.scheme == 'https'
      @connection.follow_redirect = true
      response = HTTPI.request(method, @connection)
      response.body
    end
  end
end
