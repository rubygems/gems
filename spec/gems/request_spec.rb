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
    it { expect(@connection.proxy).to eq URI('http://proxy_user:proxy_pass@192.168.1.99:9999') }
  end
end
