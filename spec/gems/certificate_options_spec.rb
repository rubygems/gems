# frozen_string_literal: true

RSpec.describe Gems::CertificateOptions do
  subject(:connection) { Gems::Connection.new }

  let(:ca_file) { certificate_path("ca.pem") }
  let(:ca_path) { certificate_path }
  let(:certificates) do
    {ca_file:, ca_path:, cert_store: OpenSSL::X509::Store.new, client_cert: test_client_cert,
     client_key: test_client_key}
  end

  # The settings read one by one, rather than through SETTINGS, so that a setting dropped from that list is caught
  # here rather than hidden by the test that reads it
  def settings_of(object)
    [object.ca_file, object.ca_path, object.cert_store, object.client_cert, object.client_key]
  end

  describe "SETTINGS" do
    it "names the certificate settings" do
      expect(described_class::SETTINGS).to eq(%i[ca_file ca_path cert_store client_cert client_key])
    end
  end

  describe "#ca_file=" do
    it "sets the path of a file of certificates" do
      connection.ca_file = ca_file

      expect(connection.ca_file).to eq(ca_file)
    end

    it "clears the path" do
      connection.ca_file = ca_file
      connection.ca_file = nil

      expect(connection.ca_file).to be_nil
    end

    it "raises for a path that names nothing" do
      expect { connection.ca_file = "/no/such/certificate.pem" }
        .to raise_error(ArgumentError, "Invalid CA file: /no/such/certificate.pem")
    end

    it "raises for a path that names a directory" do
      expect { connection.ca_file = ca_path }.to raise_error(ArgumentError, "Invalid CA file: #{ca_path}")
    end

    it "leaves the path as it was when the new one names nothing" do
      connection.ca_file = ca_file
      connection.ca_file = "/no/such/certificate.pem"
    rescue ArgumentError
      expect(connection.ca_file).to eq(ca_file)
    end
  end

  describe "#ca_path=" do
    it "sets the path of a directory of certificates" do
      connection.ca_path = ca_path

      expect(connection.ca_path).to eq(ca_path)
    end

    it "clears the path" do
      connection.ca_path = ca_path
      connection.ca_path = nil

      expect(connection.ca_path).to be_nil
    end

    it "raises for a path that names nothing" do
      expect { connection.ca_path = "/no/such/certificates" }
        .to raise_error(ArgumentError, "Invalid CA path: /no/such/certificates")
    end

    it "raises for a path that names a file" do
      expect { connection.ca_path = ca_file }.to raise_error(ArgumentError, "Invalid CA path: #{ca_file}")
    end

    it "leaves the path as it was when the new one names nothing" do
      connection.ca_path = ca_path
      connection.ca_path = "/no/such/certificates"
    rescue ArgumentError
      expect(connection.ca_path).to eq(ca_path)
    end
  end

  describe "#cert_store=" do
    it "sets the store of certificates" do
      store = OpenSSL::X509::Store.new
      connection.cert_store = store

      expect(connection.cert_store).to equal(store)
    end
  end

  describe "#client_cert=" do
    it "sets the certificate presented to a host that asks for one" do
      client_cert = test_client_cert
      connection.client_cert = client_cert

      expect(connection.client_cert).to equal(client_cert)
    end
  end

  describe "#client_key=" do
    it "sets the private key of the client certificate" do
      client_key = test_client_key
      connection.client_key = client_key

      expect(connection.client_key).to equal(client_key)
    end
  end

  describe "#initialize_certificates" do
    it "defaults every setting to nil" do
      expect(settings_of(connection)).to all(be_nil)
    end

    it "assigns every setting" do
      expect(settings_of(Gems::Connection.new(**certificates))).to eq(certificates.values)
    end

    it "raises for a path that names nothing" do
      expect { Gems::Connection.new(ca_file: "/no/such/certificate.pem") }
        .to raise_error(ArgumentError, "Invalid CA file: /no/such/certificate.pem")
    end
  end

  describe "#reset_certificates" do
    it "clears every setting" do
      Gems.configure { |config| certificates.each { |setting, value| config.public_send(:"#{setting}=", value) } }
      Gems.reset

      expect(settings_of(Gems)).to all(be_nil)
    end
  end

  describe "#certificate_settings" do
    it "answers with the value of every setting, in the order they are named" do
      expect(Gems::Connection.new(**certificates).send(:certificate_settings)).to eq(certificates.values)
    end

    it "answers with nothing set without certificates" do
      expect(connection.send(:certificate_settings)).to eq([nil, nil, nil, nil, nil])
    end
  end

  describe "#configure_certificates" do
    subject(:connection) { Gems::Connection.new(**certificates) }

    let(:uri) { URI("https://rubygems.org/path") }
    let(:http_client) { connection.send(:build_http_client, uri, connection.send(:settings_for, uri)) }

    it "hands the CA file to the HTTP client" do
      expect(http_client.ca_file).to eq(ca_file)
    end

    it "hands the CA path to the HTTP client" do
      expect(http_client.ca_path).to eq(ca_path)
    end

    it "hands the certificate store to the HTTP client" do
      expect(http_client.cert_store).to equal(certificates.fetch(:cert_store))
    end

    it "hands the client certificate to the HTTP client" do
      expect(http_client.cert).to equal(certificates.fetch(:client_cert))
    end

    it "hands the client key to the HTTP client" do
      expect(http_client.key).to equal(certificates.fetch(:client_key))
    end

    it "hands nothing to the HTTP client without certificates" do
      connection = Gems::Connection.new
      http_client = connection.send(:build_http_client, uri, connection.send(:settings_for, uri))

      expect([http_client.ca_file, http_client.ca_path, http_client.cert_store, http_client.cert, http_client.key])
        .to all(be_nil)
    end

    it "never turns verification off" do
      expect(http_client.verify_mode).not_to eq(OpenSSL::SSL::VERIFY_NONE)
    end
  end
end
