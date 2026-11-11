# frozen_string_literal: true

require "json"
require "uri"

module Gems
  # Reads the credential values a request carries, mixed into the connection
  #
  # The credentials a request carries are redacted from the debug output by the patterns that match the forms the
  # library itself writes them in (see {RedactedOutput}), but a host that echoes one of them back in a response —
  # under a name of its own, or in an encoding of its own — would carry it past the patterns, which know the names
  # the library writes. The values are therefore redacted wherever they appear as well, and the request alone
  # says which values those are: the connection reads them from the request it is sending.
  #
  # @api private
  module RequestSecrets
    private

    # The credential values a request carries
    #
    # The value of the Authorization header, the encoded and the decoded credentials of basic authentication, the
    # one-time passcode, and the ID token or the API key a body carries as a field. The values that are not
    # Strings, such as a jwt field of another type, carry nothing to redact by value and are left out.
    #
    # @api private
    # @param request [Net::HTTPRequest] the HTTP request
    # @return [Array<String>] the credential values the request carries, without repeats
    def secrets_of(request)
      authorization = request["Authorization"]
      basic = authorization&.delete_prefix("Basic ")
      [authorization, basic, *basic_secrets_of(basic), request["OTP"], *body_secrets_of(request)].compact.uniq
    end

    # The username and password basic authentication carries
    #
    # The encoded credentials of the Authorization header are decoded and split on the first colon, which is the
    # whole of the separator between a username and a password: a password may hold a colon of its own, while a
    # username may not. Credentials that decode to no colon, such as a value another authentication sent, hold
    # neither part.
    #
    # @api private
    # @param basic [String, nil] the encoded credentials, without the "Basic " that introduces them
    # @return [Array<String>] the username and the password, empty when the credentials hold neither
    def basic_secrets_of(basic)
      # The signature of Array#unpack1 is the values every format answers with, while "m0" answers a String alone
      decoded = basic&.unpack1("m0")
      return [] unless decoded&.include?(":") # steep:ignore NoMethod

      decoded.split(":", 2) # steep:ignore NoMethod
    rescue ArgumentError
      []
    end

    # The credential values a request body carries as a field
    #
    # The token exchange sends the ID token as the jwt field of a JSON body, and updating an API key sends the
    # key as the api_key field of a form body, so each is read where the body carries it. A body streamed rather
    # than set, such as the multipart body of a push, is not a String and carries nothing to read.
    #
    # @api private
    # @param request [Net::HTTPRequest] the HTTP request
    # @return [Array<String>] the credential values the body carries
    def body_secrets_of(request)
      body = request.body
      return [] unless body.is_a?(String)

      [json_secret_of(body), form_secret_of(body)].grep(String)
    end

    # The ID token a JSON body carries as its jwt field
    #
    # A body that is not JSON, or whose JSON is not an object, carries no field to read, and neither does one
    # that carries no jwt field.
    #
    # @api private
    # @param body [String] the request body
    # @return [Object, nil] the value the jwt field carries, or nil when the body carries no such field
    def json_secret_of(body)
      JSON.parse(body)["jwt"]
    rescue JSON::ParserError, NoMethodError, TypeError
      nil
    end

    # The API key a form body carries as its api_key field
    #
    # A body that is not form-encoded carries no field to read, and so does one whose encoding cannot be read,
    # such as bytes that are not text.
    #
    # @api private
    # @param body [String] the request body
    # @return [String, nil] the API key, or nil when the body carries no such field
    def form_secret_of(body)
      URI.decode_www_form(body).to_h["api_key"]
    rescue ArgumentError
      nil
    end
  end
end
