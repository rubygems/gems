RSpec.describe Gems::WebHook do
  subject(:web_hook) { described_class.new("gem_name" => "rails", "url" => "http://example.com", "failure_count" => 2) }

  it "is a Resource" do
    expect(web_hook).to be_a(Gems::Resource)
  end

  it "inspects as the gem name and URL" do
    expect(web_hook.inspect).to eq('#<Gems::WebHook gem_name="rails" url="http://example.com">')
  end

  it "exposes the gem name" do
    expect(web_hook.gem_name).to eq("rails")
  end

  it "exposes the URL" do
    expect(web_hook.url).to eq("http://example.com")
  end

  it "exposes the failure count" do
    expect(web_hook.failure_count).to eq(2)
  end
end
