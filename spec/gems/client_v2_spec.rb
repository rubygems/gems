require 'helper'

describe Gems::V2::Client do
  after do
    Gems.reset
  end

  describe '#info' do
    context 'when gem exists' do
      before do
        stub_get('/api/v2/rubygems/rails/versions/7.0.6.json').to_return(body: fixture('v2/rails-7.0.6.json'))
      end

      it 'returns some basic information about the given gem' do
        info = Gems::V2.info 'rails', '7.0.6'
        expect(a_get('/api/v2/rubygems/rails/versions/7.0.6.json')).to have_been_made
        puts info.inspect
        expect(info['name']).to eq 'rails'
        expect(info['version']).to eq '7.0.6'
      end
    end

    context 'when gem version does not exist' do
      before do
        stub_get('/api/v2/rubygems/rails/versions/7.0.99.json').to_return(body: 'This version could not be found.')
      end

      it 'returns error message' do
        info = Gems::V2.info 'rails', '7.0.99'
        expect(a_get('/api/v2/rubygems/rails/versions/7.0.99.json')).to have_been_made
        expect(info['name']).to be_nil
      end
    end

    context 'when gem does not exist' do
      before do
        stub_get('/api/v2/rubygems/nonexistentgem/versions/1.0.0.json').to_return(body: 'This gem could not be found')
      end

      it 'returns error message' do
        info = Gems::V2.info 'nonexistentgem', '1.0.0'
        expect(a_get('/api/v2/rubygems/nonexistentgem/versions/1.0.0.json')).to have_been_made
        expect(info['name']).to be_nil
      end
    end
  end
end
