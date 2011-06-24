module Gems
  module Request
    def get(path, options={}, format=format)
      request(:get, path, options, format)
    end

    private

    def request(method, path, options, format)
      response = connection(format).send(method) do |request|
        request.url(formatted_path(path, format), options)
      end
      response.body
    end

    def formatted_path(path, format)
      case format.to_s.downcase
      when 'json', 'xml'
        [path, format].compact.join('.')
      when 'marshal'
        path
      end
    end
  end
end
