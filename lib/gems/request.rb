require 'rubygems'

module Gems
  module Request
    def delete(path, options={}, content_type=nil)
      request(:delete, path, options, content_type)
    end

    def get(path, options={}, content_type=nil)
      request(:get, path, options, content_type)
    end

    def post(path, options={}, content_type=nil)
      request(:post, path, options, content_type)
    end

    def put(path, options={}, content_type=nil)
      request(:put, path, options, content_type)
    end

    private

    def request(method, path, options, content_type)
      content_length = case content_type
      when 'application/octet-stream'
        options.size
      end
      response = connection(content_length, content_type).send(method) do |request|
        case method
        when :delete, :get
          request.url(path, options)
        when :post, :put
          request.path = path
          request.body = options unless options == {}
        end
      end
      response.body
    end
  end
end
