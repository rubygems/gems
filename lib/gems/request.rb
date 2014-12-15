require 'net/http'
require 'rubygems'
require 'open-uri'

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
      path += hash_to_query_string(data) if [:delete, :get].include? method
      uri = URI.parse [request_host, path].join
      request_class = Net::HTTP.const_get method.to_s.capitalize
      request = request_class.new uri.request_uri
      request.add_field 'Authorization', key if key
      request.add_field 'Connection', 'keep-alive'
      request.add_field 'Keep-Alive', '30'
      request.add_field 'User-Agent', user_agent
      request.basic_auth username, password if username && password
      request.content_type = content_type
      case content_type
      when 'application/x-www-form-urlencoded'
        request.form_data = data if [:post, :put].include? method
      when 'application/octet-stream'
        request.body = data
        request.content_length = data.size
      end
      proxy = uri.find_proxy
      @connection = if proxy
        Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(uri.host, uri.port)
      else
        Net::HTTP.new uri.host, uri.port
      end
      if uri.scheme == 'https'
        require 'net/https'
        @connection.use_ssl = true
        @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connection.start
      response = @connection.request request
      body_from_response(response, method, content_type)
    end

    def hash_to_query_string(hash)
      return '' if hash.empty?

      hash.keys.each_with_object('?') do |key, query_string|
        query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key])}&"
      end.chop!
    end

    def body_from_response(response, method, content_type)
      if response.is_a?(Net::HTTPRedirection)
        uri = URI.parse(response['location'])
        host_with_scheme = [uri.scheme, uri.host].join('://')
        request(method, uri.request_uri, {}, content_type, host_with_scheme)
      else
        response.body
      end
    end
  end
end
