require 'net/http'
require 'rubygems'
require 'uri'

module Gems
  module Request
    def delete(path, data={}, content_type='application/x-www-form-urlencoded')
      request(:delete, path, data, content_type)
    end

    def get(path, data={}, content_type='application/x-www-form-urlencoded')
      request(:get, path, data, content_type)
    end

    def post(path, data={}, content_type='application/x-www-form-urlencoded')
      request(:post, path, data, content_type)
    end

    def put(path, data={}, content_type='application/x-www-form-urlencoded')
      request(:put, path, data, content_type)
    end

    private

    def request(method, path, data, content_type, host=host)
      path = [path, hash_to_query_string(data)[/.+/]].compact.join('?') if [:delete, :get].include? method
      uri = URI.parse [host, path].join
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
      connection = Net::HTTP.new uri.host, uri.port
      if uri.scheme == 'https'
        require 'net/https'
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      connection.start
      response = connection.request request
      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        request(method, path, data, content_type, response['location'])
      end
    end

    def hash_to_query_string(hash)
      hash.keys.inject('') do |query_string, key|
        query_string << '&' unless key == hash.keys.first
        query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key])}"
      end
    end
  end
end
