require 'helper'

describe Gems::Request do
  after do
    Gems.reset
  end

  describe '#get with redirect' do
    before do
      response_body = '<html>\r\n<head><title>302 Found</title></head>\r\n<body bgcolor=\"white\">\r\n<center><h1>302 Found</h1></center>\r\n<hr><center>nginx</center>\r\n</body>\r\n</html>\r\n'
      response_location = 'https://bundler.rubygems.org/api/v1/dependencies?gems=rails,thor'

      stub_get('/api/v1/dependencies').
        with(:query => {'gems' => 'rails,thor'}).
        to_return(:body => response_body, :status => 302, :headers => {:location => response_location})
      stub_request(:get, 'https://bundler.rubygems.org/api/v1/dependencies').
        with(:query => {'gems' => 'rails,thor'}).
        to_return(:body => fixture('dependencies'), :status => 200, :headers => {})
    end
    it 'returns an array of hashes for all versions of given gems' do
      dependencies = Gems.dependencies 'rails', 'thor'
      expect(a_get('/api/v1/dependencies').with(:query => {'gems' => 'rails,thor'})).to have_been_made
      expect(a_get('https://bundler.rubygems.org/api/v1/dependencies').with(:query => {'gems' => 'rails,thor'})).to have_been_made
      expect(dependencies.first[:number]).to eq '3.0.9'
    end
  end

  describe 'credentials on a redirect' do
    before do
      Gems.configure do |config|
        config.key = '701243f217cdf23b1370c7b66b65ca97'
        config.username = 'nick@gemcutter.org'
        config.password = 'schwwwwing'
      end
    end

    def redirect(from, to)
      stub_request(:get, from).to_return(:status => 302, :headers => {:location => to})
    end

    def authorization_sent_to(url)
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys.
        select { |signature| signature.uri == WebMock::Util::URI.normalize_uri(url) }.
        map { |signature| signature.headers && signature.headers['Authorization'] }
    end

    it 'keeps the credentials for a redirect to the same origin' do
      redirect('https://rubygems.org/api/v1/gems/rails.json', 'https://rubygems.org/api/v1/gems/rails2.json')
      stub_get('/api/v1/gems/rails2.json').to_return(:body => fixture('rails.json'))
      Gems.info 'rails'
      expect(authorization_sent_to('https://rubygems.org/api/v1/gems/rails2.json')).to eq ['Basic bmlja0BnZW1jdXR0ZXIub3JnOnNjaHd3d3dpbmc=']
    end

    {
      'another host' => 'https://evil.example/collect',
      'another scheme' => 'http://rubygems.org/collect',
    }.each do |change, location|
      it "drops the credentials for a redirect to #{change}" do
        redirect('https://rubygems.org/api/v1/gems/rails.json', location)
        stub_request(:get, location).to_return(:body => fixture('rails.json'))
        Gems.info 'rails'
        expect(authorization_sent_to(location)).to eq [nil]
      end
    end

    it 'drops the API key for a redirect to another host' do
      Gems.configure do |config|
        config.username = nil
        config.password = nil
      end
      redirect('https://rubygems.org/api/v1/gems/rails.json', 'https://evil.example/collect')
      stub_request(:get, 'https://evil.example/collect').to_return(:body => fixture('rails.json'))
      Gems.info 'rails'
      expect(authorization_sent_to('https://evil.example/collect')).to eq [nil]
    end

    it 'does not restore the credentials for a redirect back to the origin' do
      redirect('https://rubygems.org/api/v1/gems/rails.json', 'https://evil.example/collect')
      redirect('https://evil.example/collect', 'https://rubygems.org/api/v1/gems/rails2.json')
      stub_get('/api/v1/gems/rails2.json').to_return(:body => fixture('rails.json'))
      Gems.info 'rails'
      expect(authorization_sent_to('https://rubygems.org/api/v1/gems/rails2.json')).to eq [nil]
    end
  end

  describe '#get with 404' do
    before do
      response_body = 'This rubygem could not be found.'

      stub_get('/api/v1/dependencies').
        with(:query => {'gems' => 'rails,thor'}).
        to_return(:body => response_body, :status => 404)
    end

    it 'raise a Gems::NotFound error' do
      expect { Gems.dependencies('rails', 'thor') }.to raise_error(Gems::NotFound)
    end
  end

  describe "#get with a non-200" do
    before do
      response_body = 'Internal Server Error'

      stub_get('/api/v1/dependencies').
        with(:query => {'gems' => 'rails,thor'}).
        to_return(:body => response_body, :status => 500)
    end

    it 'raise a wrapped Gems::Error' do
      expect { Gems.dependencies('rails', 'thor') }.to raise_error(Gems::GemError)
      expect(a_get('/api/v1/dependencies').with(:query => {'gems' => 'rails,thor'})).to have_been_made
    end
  end

  describe 'request behind proxy' do
    before do
      allow(ENV).to receive(:[]).with('no_proxy').and_return('')
      allow(ENV).to receive(:[]).with('https_proxy').and_return('http://proxy_user:proxy_pass@192.168.1.99:9999')
      stub_get('/api/v1/gems/rails.json').
        to_return(:body => fixture('rails.json'))
      gems = Gems.new
      gems.info 'rails'
      @connection = gems.instance_variable_get(:@connection)
    end
    it { expect(@connection.proxy_address).to eq '192.168.1.99' }
    it { expect(@connection.proxy_user).to eq 'proxy_user' }
    it { expect(@connection.proxy_pass).to eq 'proxy_pass' }
    it { expect(@connection.proxy_port).to eq 9999 }
  end
end
