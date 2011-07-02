require 'rubygems'

module Gems
  module Request
    def delete(path, options={}, format=format, content_type=nil)
      request(:delete, path, options, format, content_type)
    end

    def get(path, options={}, format=format, content_type=nil)
      request(:get, path, options, format, content_type)
    end

    def post(path, options={}, format=format, content_type=nil)
      request(:post, path, options, format, content_type)
    end

    def put(path, options={}, format=format, content_type=nil)
      request(:put, path, options, format, content_type)
    end

    private

    def request(method, path, options, format, content_type)
      content_length = case content_type
      when 'application/octet-stream'
        options.size
      end
      response = connection(content_length, content_type, format).send(method) do |request|
        case method
        when :delete, :get
          request.url(formatted_path(path, format), options)
        when :post, :put
          request.path = formatted_path(path, format)
          request.body = options unless options == {}
        end
      end
      response.body
    end

    def formatted_path(path, format)
      case format.to_s.downcase
      when 'json', 'xml', 'yaml'
        [path, format].compact.join('.')
      when 'marshal', 'raw'
        path
      end
    end
  end
end
