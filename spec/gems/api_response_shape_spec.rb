# frozen_string_literal: true

# Every endpoint that builds resources from its response raises InvalidResponse, with the body the host sent, for JSON
# that parses but is not the shape the endpoint reads: a scalar or null, an object where a list is read (which would
# otherwise map over its pairs, or answer an empty object as no results), a list where an object is read, or a list
# whose elements are not objects.
RSpec.describe Gems::API do
  let(:client) { Gems::Client.new(key: TEST_KEY) }
  let(:password_client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

  not_a_list = ['"teapot"', "null", "1", "{}", '{"a":1}', '["teapot"]', "[null]", "[[]]"]
  not_an_object = ['"teapot"', "null", "1", "[]", '["teapot"]', "[{}]"]

  endpoints = {
    latest: [:get, "/api/v1/activity/latest.json", not_a_list, -> { client.latest }],
    just_updated: [:get, "/api/v1/activity/just_updated.json", not_a_list, -> { client.just_updated }],
    search: [:get, "/api/v1/search.json", not_a_list, -> { client.search("rails") }],
    owned_gems: [:get, "/api/v1/gems.json", not_a_list, -> { client.owned_gems }],
    timeframe_versions: [:get, "/api/v1/timeframe_versions.json", not_a_list,
      -> { client.timeframe_versions(from: "2026-01-01T00:00:00Z") }],
    versions: [:get, "/api/v1/versions/rails.json", not_a_list, -> { client.versions("rails") }],
    owners: [:get, "/api/v1/gems/rails/owners.json", not_a_list, -> { client.owners("rails") }],
    trusted_publishers: [:get, "/api/v1/gems/rails/trusted_publishers", not_a_list,
      -> { client.trusted_publishers("rails") }],
    api_key_roles: [:get, "/api/v1/oidc/api_key_roles.json", not_a_list, -> { client.api_key_roles }],
    oidc_providers: [:get, "/api/v1/oidc/providers.json", not_a_list, -> { client.oidc_providers }],
    oidc_id_tokens: [:get, "/api/v1/oidc/id_tokens.json", not_a_list, -> { client.oidc_id_tokens }],
    most_downloaded: [:get, "/api/v1/downloads/all.json",
      ['"teapot"', "null", "[]", "{}", '{"gems":{}}', '{"gems":"teapot"}', '{"gems":["teapot"]}', '{"gems":[[1,2]]}'],
      -> { client.most_downloaded }],
    web_hooks: [:get, "/api/v1/web_hooks.json",
      ['"teapot"', "null", '["teapot"]', '{"a":1}', '{"a":["teapot"]}'], -> { client.web_hooks }],
    rubygem: [:get, "/api/v1/gems/rails.json", not_an_object, -> { client.rubygem("rails") }],
    version: [:get, "/api/v2/rubygems/rails/versions/7.0.6.json", not_an_object, -> { client.version("rails", "7.0.6") }],
    downloads: [:get, "/api/v1/downloads/rails-7.0.6.json", not_an_object, -> { client.downloads("rails", "7.0.6") }],
    profile: [:get, "/api/v1/profiles/qrush.json", not_an_object, -> { client.profile("qrush") }],
    me: [:get, "/api/v1/profile/me.json", not_an_object, -> { client.me }],
    webauthn_verification: [:post, "/api/v1/webauthn_verification.json", not_an_object,
      -> { client.webauthn_verification }],
    webauthn_verification_status: [:get, "/api/v1/webauthn_verification/odow34b93t6aPCdY/status.json", not_an_object,
      -> { client.webauthn_verification_status("odow34b93t6aPCdY") }],
    trusted_publisher: [:get, "/api/v1/gems/rails/trusted_publishers/1", not_an_object,
      -> { client.trusted_publisher("rails", 1) }],
    add_trusted_publisher: [:post, "/api/v1/gems/rails/trusted_publishers", not_an_object,
      -> { client.add_trusted_publisher("rails", repository_owner: "rails", repository_name: "rails", workflow_filename: "push.yml") }],
    api_key_role: [:get, "/api/v1/oidc/api_key_roles/0123456789abcdef0123456789abcdef.json", not_an_object,
      -> { client.api_key_role("0123456789abcdef0123456789abcdef") }],
    oidc_provider: [:get, "/api/v1/oidc/providers/1.json", not_an_object, -> { client.oidc_provider(1) }],
    oidc_id_token: [:get, "/api/v1/oidc/id_tokens/1.json", not_an_object, -> { client.oidc_id_token(1) }],
    create_api_key: [:post, "/api/v1/api_key.json", not_an_object,
      -> { password_client.create_api_key("ci-push", scopes: %i[push_rubygem]) }]
  }

  endpoints.each do |endpoint, (method, path, bodies, call)|
    describe "##{endpoint}" do
      bodies.each do |body|
        it "raises InvalidResponse, with the body attached, for #{body}" do
          stub_request(method, /\A#{Regexp.escape(TEST_HOST + path)}(\?|\z)/).to_return(body:)

          expect { instance_exec(&call) }
            .to raise_error(an_instance_of(Gems::InvalidResponse).and(having_attributes(body:)))
        end
      end
    end
  end
end
