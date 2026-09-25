# frozen_string_literal: true

module Gems
  # The certificates TLS is verified with and presented by, mixed into the configuration and the connection
  #
  # A host whose certificate Ruby's OpenSSL does not already trust, such as a private gem server with one of its
  # own, is reached by naming that certificate here rather than by turning verification off: there is no option for
  # that, so a request of this library is always verified. A host that asks the client for a certificate of its own
  # is given {#client_cert} and {#client_key}.
  #
  # The paths are checked where they are assigned, as a host and a proxy URL are (see {URLValidation}), so that a
  # path that names nothing is reported as the assignment that was wrong instead of as the TLS failure of the next
  # request. The value that is rejected is left as it was.
  #
  # The configuration uses these as options; the connection also hands them to the HTTP client it opens.
  #
  # @api private
  module CertificateOptions
    # The names of the settings, which are the options of {Client} and of the {Gems} module that name certificates
    SETTINGS = %i[ca_file ca_path cert_store client_cert client_key].freeze

    # The path of a file of certificates TLS is verified with
    #
    # The certificates in the file are trusted alongside the ones OpenSSL already trusts.
    #
    # @api private
    # @return [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    # @example Get the CA file
    #   connection.ca_file
    attr_reader :ca_file

    # The path of a directory of certificates TLS is verified with
    #
    # The directory holds the certificates under the hashed names `openssl rehash` gives them.
    #
    # @api private
    # @return [String, nil] the path of the directory, or nil to verify with the certificates OpenSSL trusts
    # @example Get the CA path
    #   connection.ca_path
    attr_reader :ca_path

    # The store of certificates TLS is verified with
    #
    # A store of your own replaces the certificates OpenSSL trusts, where {#ca_file} and {#ca_path} add to them.
    #
    # @api private
    # @return [OpenSSL::X509::Store, nil] the store, or nil to verify with the certificates OpenSSL trusts
    # @example Get or set the certificate store
    #   connection.cert_store = OpenSSL::X509::Store.new
    attr_accessor :cert_store

    # The certificate presented to a host that asks the client for one
    #
    # @api private
    # @return [OpenSSL::X509::Certificate, nil] the certificate, or nil to present none
    # @example Get or set the client certificate
    #   connection.client_cert = OpenSSL::X509::Certificate.new(File.read("client.pem"))
    attr_accessor :client_cert

    # The private key of {#client_cert}
    #
    # @api private
    # @return [OpenSSL::PKey::PKey, nil] the private key, or nil to present no certificate
    # @example Get or set the client key
    #   connection.client_key = OpenSSL::PKey::RSA.new(File.read("client.key"))
    attr_accessor :client_key

    # Set the path of a file of certificates TLS is verified with
    #
    # @api private
    # @param ca_file [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    # @return [void]
    # @raise [ArgumentError] if the path does not name a file, in which case the path is left as it was
    # @example Set the CA file
    #   connection.ca_file = "/etc/ssl/certs/internal.pem"
    def ca_file=(ca_file)
      @ca_file = ca_file && validate_ca_file(ca_file)
    end

    # Set the path of a directory of certificates TLS is verified with
    #
    # @api private
    # @param ca_path [String, nil] the path of the directory, or nil to verify with the certificates OpenSSL trusts
    # @return [void]
    # @raise [ArgumentError] if the path does not name a directory, in which case the path is left as it was
    # @example Set the CA path
    #   connection.ca_path = "/etc/ssl/certs"
    def ca_path=(ca_path)
      @ca_path = ca_path && validate_ca_path(ca_path)
    end

    private

    # Assign every certificate setting
    #
    # The paths are assigned through their setters, so that one naming nothing is reported here.
    #
    # @api private
    # @param settings [Hash{Symbol => Object}] the settings, which are the ones {SETTINGS} names
    # @return [void]
    # @raise [ArgumentError] if a path names nothing
    def initialize_certificates(**settings)
      SETTINGS.each { |setting| public_send(:"#{setting}=", settings.fetch(setting)) }
    end

    # Reset every certificate setting to nil
    #
    # TLS is then verified with the certificates OpenSSL trusts.
    #
    # @api private
    # @return [void]
    def reset_certificates
      SETTINGS.each { |setting| public_send(:"#{setting}=", nil) }
    end

    # The values of the certificate settings, for telling one set of them from another
    # @api private
    # @return [Array<Object>] the values, in the order {SETTINGS} names them
    def certificate_settings
      SETTINGS.map { |setting| public_send(setting) }
    end

    # Hand certificates to an HTTP client
    #
    # They are assigned whatever the scheme of the request is, as the timeouts are: Net::HTTP reads them only when
    # it opens a TLS connection.
    #
    # @api private
    # @param http_client [Net::HTTP] the HTTP client
    # @param certificates [Array<Object>] the values of the certificate settings, as {#certificate_settings} reads
    #   them
    # @return [void]
    def configure_certificates(http_client, certificates)
      http_client.ca_file, http_client.ca_path, http_client.cert_store, http_client.cert, http_client.key = certificates
    end

    # Check that a path names a file of certificates
    # @api private
    # @param ca_file [String] the path of the file
    # @return [String] the path
    # @raise [ArgumentError] if the path does not name a file
    def validate_ca_file(ca_file)
      raise ArgumentError, "Invalid CA file: #{ca_file}" unless File.file?(ca_file)

      ca_file
    end

    # Check that a path names a directory of certificates
    # @api private
    # @param ca_path [String] the path of the directory
    # @return [String] the path
    # @raise [ArgumentError] if the path does not name a directory
    def validate_ca_path(ca_path)
      raise ArgumentError, "Invalid CA path: #{ca_path}" unless File.directory?(ca_path)

      ca_path
    end
  end
end
