require 'helper'

describe Gems::Client do
  after do
    Gems.reset
  end

  describe '#new' do
    it 'creates a new v1 client' do
      client = Gems::V1.new

      expect(client).to_not be_nil
      expect(client.class).to eq(Gems::V1::Client)
    end
  end

  describe '#info' do
    context 'when gem exists' do
      before do
        stub_get('/api/v1/gems/rails.json').
          to_return(:body => fixture('rails.json'))
      end
      it 'returns some basic information about the given gem' do
        info = Gems.info 'rails'
        expect(a_get('/api/v1/gems/rails.json')).to have_been_made
        expect(info['name']).to eq 'rails'
      end
    end

    context 'when gem does not exist' do
      before do
        stub_get('/api/v1/gems/nonexistentgem.json').
          to_return(:body => 'This rubygem could not be found.')
      end
      it 'returns some basic information about the given gem' do
        info = Gems.info 'nonexistentgem'
        expect(a_get('/api/v1/gems/nonexistentgem.json')).to have_been_made
        expect(info['name']).to be_nil
      end
    end
  end

  describe '#search' do
    before do
      stub_get('/api/v1/search.json').
        with(:query => {'query' => 'cucumber'}).
        to_return(:body => fixture('search.json'))
      stub_get('/api/v1/search.json').
        with(:query => {'query' => 'cucumber', 'page' => '2'}).
        to_return(:body => fixture('search.json'))
    end
    it 'returns an array of active gems that match the query' do
      search = Gems.search 'cucumber'
      expect(a_get('/api/v1/search.json').with(:query => {'query' => 'cucumber'})).to have_been_made
      expect(search.first['name']).to eq 'cucumber'
    end
    it 'allows passing a page parameter' do
      Gems.search 'cucumber', :page => 2
      expect(a_get('/api/v1/search.json').with(:query => {'query' => 'cucumber', 'page' => '2'})).to have_been_made
    end
  end

  describe '#gems' do
    context 'with no user handle specified' do
      before do
        stub_get('/api/v1/gems.json').
          to_return(:body => fixture('gems.json'))
      end
      it 'lists all gems that you own' do
        gems = Gems.gems
        expect(a_get('/api/v1/gems.json')).to have_been_made
        expect(gems.first['name']).to eq 'exchb'
      end
    end
    context 'with a user handle specified' do
      before do
        stub_get('/api/v1/owners/sferik/gems.json').
          to_return(:body => fixture('gems.json'))
      end
      it 'lists all gems that the specified user owns' do
        gems = Gems.gems('sferik')
        expect(a_get('/api/v1/owners/sferik/gems.json')).to have_been_made
        expect(gems.first['name']).to eq 'exchb'
      end
    end
  end

  describe '#push' do
    context 'without the host parameter' do
      before do
        stub_post('/api/v1/gems').
          to_return(:body => fixture('push'))
      end

      it 'submits a gem to RubyGems.org' do
        push = Gems.push(File.new(File.expand_path('../../fixtures/gems-0.0.8.gem', __FILE__), 'rb'))
        expect(a_post('/api/v1/gems')).to have_been_made
        expect(push).to eq 'Successfully registered gem: gems (0.0.8)'
      end
    end

    context 'with the host parameter' do
      before do
        stub_post('http://example.com/api/v1/gems').
          to_return(:body => fixture('push'))
      end
      it 'submits a gem to the passed host' do
        push = Gems.push(File.new(File.expand_path('../../fixtures/gems-0.0.8.gem', __FILE__), 'rb'), 'http://example.com')
        expect(a_post('http://example.com/api/v1/gems'))
        expect(push).to eq 'Successfully registered gem: gems (0.0.8)'
      end
    end

    context 'with the attestations parameter' do
      before do
        stub_post('/api/v1/gems').
          to_return(:body => fixture('push'))
      end
      it 'submits a gem to RubyGems.org with attestations' do
        push = Gems.push(File.new(File.expand_path('../../fixtures/gems-0.0.8.gem', __FILE__), 'rb'), :attestations => [File.new(File.expand_path('../../fixtures/gems-0.0.8.gem', __FILE__), 'rb')])
        expect(a_post('/api/v1/gems')).to have_been_made
        expect(push).to eq 'Successfully registered gem: gems (0.0.8)'
      end
    end
  end

  describe '#yank' do
    context 'with no version specified' do
      before do
        stub_get('/api/v1/gems/gems.json').
          to_return(:body => fixture('rails.json'))
        stub_delete('/api/v1/gems/yank').
          with(:query => {:gem_name => 'gems', :version => '3.0.9'}).
          to_return(:body => fixture('yank'))
      end
      it "removes a gem from RubyGems.org's index" do
        yank = Gems.yank('gems')
        expect(a_delete('/api/v1/gems/yank').with(:query => {:gem_name => 'gems', :version => '3.0.9'})).to have_been_made
        expect(yank).to eq 'Successfully yanked gem: gems (0.0.8)'
      end
    end
    context 'with a version specified' do
      before do
        stub_delete('/api/v1/gems/yank').
          with(:query => {:gem_name => 'gems', :version => '0.0.8'}).
          to_return(:body => fixture('yank'))
      end
      it "removes a gem from RubyGems.org's index" do
        yank = Gems.yank('gems', '0.0.8')
        expect(a_delete('/api/v1/gems/yank').with(:query => {:gem_name => 'gems', :version => '0.0.8'})).to have_been_made
        expect(yank).to eq 'Successfully yanked gem: gems (0.0.8)'
      end
    end
  end

  describe '#unyank' do
    context 'with no version specified' do
      before do
        stub_get('/api/v1/gems/gems.json').
          to_return(:body => fixture('rails.json'))
        stub_put('/api/v1/gems/unyank').
          with(:body => {:gem_name => 'gems', :version => '3.0.9'}).
          to_return(:body => fixture('unyank'))
      end
      it "updates a previously yanked gem back into RubyGems.org's index" do
        unyank = Gems.unyank('gems')
        expect(a_put('/api/v1/gems/unyank').with(:body => {:gem_name => 'gems', :version => '3.0.9'})).to have_been_made
        expect(unyank).to eq 'Successfully unyanked gem: gems (0.0.8)'
      end
    end
    context 'with a version specified' do
      before do
        stub_put('/api/v1/gems/unyank').
          with(:body => {:gem_name => 'gems', :version => '0.0.8'}).
          to_return(:body => fixture('unyank'))
      end
      it "updates a previously yanked gem back into RubyGems.org's index" do
        unyank = Gems.unyank('gems', '0.0.8')
        expect(a_put('/api/v1/gems/unyank').with(:body => {:gem_name => 'gems', :version => '0.0.8'})).to have_been_made
        expect(unyank).to eq 'Successfully unyanked gem: gems (0.0.8)'
      end
    end
  end

  describe '#versions' do
    before do
      stub_get('/api/v1/versions/script_helpers.json').
        to_return(:body => fixture('script_helpers.json'))
    end
    it 'returns an array of gem version details' do
      versions = Gems.versions 'script_helpers'
      expect(a_get('/api/v1/versions/script_helpers.json')).to have_been_made
      expect(versions.first['number']).to eq '0.1.0'
    end
  end

  describe '#latest_version' do
    before do
      stub_get('/api/v1/versions/script_helpers/latest.json').
        to_return(:body => fixture('script_helpers/latest.json'))
    end
    it 'returns an hash of gem latest version' do
      latest_version = Gems.latest_version 'script_helpers'
      expect(a_get('/api/v1/versions/script_helpers/latest.json')).to have_been_made
      expect(latest_version['version']).to eq '0.3.0'
    end
  end

  describe '#total_downloads' do
    context 'with no version or gem name specified' do
      before do
        stub_get('/api/v1/downloads.json').
          to_return(:body => fixture('total_downloads.json'))
      end
      it 'returns the total number of downloads on RubyGems.org' do
        downloads = Gems.total_downloads
        expect(a_get('/api/v1/downloads.json')).to have_been_made
        expect(downloads[:total]).to eq 244_368_950
      end
    end
    context 'with no version specified' do
      before do
        stub_get('/api/v1/gems/rails_admin.json').
          to_return(:body => fixture('rails.json'))
        stub_get('/api/v1/downloads/rails_admin-3.0.9.json').
          to_return(:body => fixture('rails_admin-0.0.0.json'))
      end
      it 'returns the total number of downloads for the specified gem' do
        downloads = Gems.total_downloads('rails_admin')
        expect(a_get('/api/v1/gems/rails_admin.json')).to have_been_made
        expect(a_get('/api/v1/downloads/rails_admin-3.0.9.json')).to have_been_made
        expect(downloads[:version_downloads]).to eq 3142
        expect(downloads[:total_downloads]).to eq 3142
      end
    end
    context 'with a version specified' do
      before do
        stub_get('/api/v1/downloads/rails_admin-0.0.0.json').
          to_return(:body => fixture('rails_admin-0.0.0.json'))
      end
      it 'returns the total number of downloads for the specified gem' do
        downloads = Gems.total_downloads('rails_admin', '0.0.0')
        expect(a_get('/api/v1/downloads/rails_admin-0.0.0.json')).to have_been_made
        expect(downloads[:version_downloads]).to eq 3142
        expect(downloads[:total_downloads]).to eq 3142
      end
    end
  end

  describe '#most_downloaded' do
    context 'with nothing specified' do
      before do
        stub_get('/api/v1/downloads/all.json').
          to_return(:body => fixture('most_downloaded.json'))
      end
      it 'returns the most downloaded versions' do
        most_downloaded = Gems.most_downloaded
        expect(a_get('/api/v1/downloads/all.json')).to have_been_made
        expect(most_downloaded.first.first['full_name']).to eq 'abstract-1.0.0'
        expect(most_downloaded.first.last).to eq 1
      end
    end
  end

  describe '#downloads' do
    context 'with no dates or version specified' do
      before do
        stub_get('/api/v1/gems/coulda.json').
          to_return(:body => fixture('rails.json'))
        stub_get('/api/v1/versions/coulda-3.0.9/downloads.json').
          to_return(:body => fixture('downloads.json'))
      end
      it 'returns the number of downloads by day for a particular gem version' do
        downloads = Gems.downloads 'coulda'
        expect(a_get('/api/v1/gems/coulda.json')).to have_been_made
        expect(a_get('/api/v1/versions/coulda-3.0.9/downloads.json')).to have_been_made
        expect(downloads['2011-06-22']).to eq 8
      end
    end
    context 'with no dates specified' do
      before do
        stub_get('/api/v1/versions/coulda-0.6.3/downloads.json').
          to_return(:body => fixture('downloads.json'))
      end
      it 'returns the number of downloads by day for a particular gem version' do
        downloads = Gems.downloads 'coulda', '0.6.3'
        expect(a_get('/api/v1/versions/coulda-0.6.3/downloads.json')).to have_been_made
        expect(downloads['2011-06-22']).to eq 8
      end
    end
    context 'with from date specified' do
      before do
        stub_get('/api/v1/versions/coulda-0.6.3/downloads/search.json').
          with(:query => {'from' => '2011-01-01', 'to' => Date.today.to_s}).
          to_return(:body => fixture('downloads.json'))
      end
      it 'returns the number of downloads by day for a particular gem version' do
        downloads = Gems.downloads 'coulda', '0.6.3', Date.parse('2011-01-01')
        expect(a_get('/api/v1/versions/coulda-0.6.3/downloads/search.json').with(:query => {'from' => '2011-01-01', 'to' => Date.today.to_s})).to have_been_made
        expect(downloads['2011-06-22']).to eq 8
      end
    end
    context 'with from and to dates specified' do
      before do
        stub_get('/api/v1/versions/coulda-0.6.3/downloads/search.json').
          with(:query => {'from' => '2011-01-01', 'to' => '2011-06-28'}).
          to_return(:body => fixture('downloads.json'))
      end
      it 'returns the number of downloads by day for a particular gem version' do
        downloads = Gems.downloads 'coulda', '0.6.3', Date.parse('2011-01-01'), Date.parse('2011-06-28')
        expect(a_get('/api/v1/versions/coulda-0.6.3/downloads/search.json').with(:query => {'from' => '2011-01-01', 'to' => '2011-06-28'})).to have_been_made
        expect(downloads['2011-06-22']).to eq 8
      end
    end
  end

  describe '#owners' do
    before do
      stub_get('/api/v1/gems/gems/owners.json').
        to_return(:body => fixture('owners.json'))
    end
    it 'lists all owners of a gem' do
      owners = Gems.owners('gems')
      expect(a_get('/api/v1/gems/gems/owners.json')).to have_been_made
      expect(owners.first['email']).to eq 'sferik@gmail.com'
    end
  end

  describe '#add_owner' do
    before do
      stub_post('/api/v1/gems/gems/owners').
        with(:body => {:email => 'sferik@gmail.com'}).
        to_return(:body => fixture('add_owner'))
    end
    it 'adds an owner to a RubyGem' do
      owner = Gems.add_owner('gems', 'sferik@gmail.com')
      expect(a_post('/api/v1/gems/gems/owners').with(:body => {:email => 'sferik@gmail.com'})).to have_been_made
      expect(owner).to eq 'Owner added successfully.'
    end
  end

  describe '#remove_owner' do
    before do
      stub_delete('/api/v1/gems/gems/owners').
        with(:query => {:email => 'sferik@gmail.com'}).
        to_return(:body => fixture('remove_owner'))
    end
    it 'removes an owner from a RubyGem' do
      owner = Gems.remove_owner('gems', 'sferik@gmail.com')
      expect(a_delete('/api/v1/gems/gems/owners').with(:query => {:email => 'sferik@gmail.com'})).to have_been_made
      expect(owner).to eq 'Owner removed successfully.'
    end
  end

  describe '#web_hooks' do
    before do
      stub_get('/api/v1/web_hooks.json').
        to_return(:body => fixture('web_hooks.json'))
    end
    it 'lists the web hooks registered under your account' do
      web_hooks = Gems.web_hooks
      expect(a_get('/api/v1/web_hooks.json')).to have_been_made
      expect(web_hooks['all gems'].first['url']).to eq 'http://example.com'
    end
  end

  describe '#add_web_hook' do
    before do
      stub_post('/api/v1/web_hooks').
        with(:body => {:gem_name => '*', :url => 'http://example.com'}).
        to_return(:body => fixture('add_web_hook'))
    end
    it 'adds a web hook' do
      add_web_hook = Gems.add_web_hook('*', 'http://example.com')
      expect(a_post('/api/v1/web_hooks').with(:body => {:gem_name => '*', :url => 'http://example.com'})).to have_been_made
      expect(add_web_hook).to eq 'Successfully created webhook for all gems to http://example.com'
    end
  end

  describe '#remove_web_hook' do
    before do
      stub_delete('/api/v1/web_hooks/remove').
        with(:query => {:gem_name => '*', :url => 'http://example.com'}).
        to_return(:body => fixture('remove_web_hook'))
    end
    it 'removes a web hook' do
      remove_web_hook = Gems.remove_web_hook('*', 'http://example.com')
      expect(a_delete('/api/v1/web_hooks/remove').with(:query => {:gem_name => '*', :url => 'http://example.com'})).to have_been_made
      expect(remove_web_hook).to eq 'Successfully removed webhook for all gems to http://example.com'
    end
  end

  describe '#fire_web_hook' do
    before do
      stub_post('/api/v1/web_hooks/fire').
        with(:body => {:gem_name => '*', :url => 'http://example.com'}).
        to_return(:body => fixture('fire_web_hook'))
    end
    it 'fires a web hook' do
      fire_web_hook = Gems.fire_web_hook('*', 'http://example.com')
      expect(a_post('/api/v1/web_hooks/fire').with(:body => {:gem_name => '*', :url => 'http://example.com'})).to have_been_made
      expect(fire_web_hook).to eq 'Successfully deployed webhook for gemcutter to http://example.com'
    end
  end

  describe '#latest' do
    before do
      stub_get('/api/v1/activity/latest.json').
        to_return(:body => fixture('latest.json'))
    end
    it 'returns some basic information about the given gem' do
      latest = Gems.latest
      expect(a_get('/api/v1/activity/latest.json')).to have_been_made
      expect(latest.first['name']).to eq 'seanwalbran-rpm_contrib'
    end
  end

  describe '#just_updated' do
    before do
      stub_get('/api/v1/activity/just_updated.json').
        to_return(:body => fixture('just_updated.json'))
    end
    it 'returns some basic information about the given gem' do
      just_updated = Gems.just_updated
      expect(a_get('/api/v1/activity/just_updated.json')).to have_been_made
      expect(just_updated.first['name']).to eq 'rspec-tag_matchers'
    end
  end

  describe '#api_key' do
    before do
      Gems.configure do |config|
        config.username = 'nick@gemcutter.org'
        config.password = 'schwwwwing'
      end
      stub_get('https://rubygems.org/api/v1/api_key').
        to_return(:body => fixture('api_key'))
    end
    it 'retrieves an API key' do
      api_key = Gems.api_key
      expect(a_get('https://rubygems.org/api/v1/api_key')).to have_been_made
      expect(api_key).to eq '701243f217cdf23b1370c7b66b65ca97'
    end
  end

  describe '#dependencies' do
    before do
      stub_get('/api/v1/dependencies').
        with(:query => {'gems' => 'rails,thor'}).
        to_return(:body => fixture('dependencies'))
    end
    it 'returns an array of hashes for all versions of given gems' do
      dependencies = Gems.dependencies 'rails', 'thor'
      expect(a_get('/api/v1/dependencies').with(:query => {'gems' => 'rails,thor'})).to have_been_made
      expect(dependencies.first[:number]).to eq '3.0.9'
    end
  end

  describe '#reverse_dependencies' do
    before do
      stub_get('/api/v1/gems/rspec/reverse_dependencies.json').
        to_return(:body => fixture('reverse_dependencies_short.json'))
    end

    it 'returns an array of names for all gems which are reverse dependencies to the given gem' do
      reverse_dependencies = Gems.reverse_dependencies 'rspec'
      expect(a_get('/api/v1/gems/rspec/reverse_dependencies.json')).to have_been_made
      expect(reverse_dependencies).to be_an_instance_of Array
    end
  end
end
