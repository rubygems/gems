module Gems
  module Request
    def delete(path, options={}, format=format)
      request(:delete, path, options, format)
    end

    def get(path, options={}, format=format)
      request(:get, path, options, format)
    end

    def post(path, options={}, format=format)
      request(:post, path, options, format)
    end

    private

    def request(method, path, options, format)
      response = connection(format).send(method) do |request|
        case method
        when :delete, :get
          request.url(formatted_path(path, format), options)
        when :post
          request.path = formatted_path(path, format)
          request.body = options unless options.empty?
        end
      end
      response.body
    end

    def formatted_path(path, format)
      case format.to_s.downcase
      when 'json', 'xml'
        [path, format].compact.join('.')
      when 'marshal', 'raw'
        path
      end
    end
  end
end
