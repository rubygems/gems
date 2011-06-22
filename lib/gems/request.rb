module Gems
  module Request
    def get(path, options={}, format=:json)
      request(:get, path, options, format)
    end

    private

    def request(method, path, options, format)
      response = connection(format).send(method) do |request|
        request.url(path, options)
      end
      response.body
    end
  end
end
