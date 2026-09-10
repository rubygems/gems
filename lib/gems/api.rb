require_relative "api/activity_endpoints"
require_relative "api/api_key_endpoints"
require_relative "api/download_endpoints"
require_relative "api/gem_endpoints"
require_relative "api/owner_endpoints"
require_relative "api/profile_endpoints"
require_relative "api/version_endpoints"
require_relative "api/web_hook_endpoints"

module Gems
  # The RubyGems API endpoints, mixed into {Client}
  #
  # The endpoints are grouped into one mixin per topic, following the sections of the RubyGems.org API guide.
  # Every public method of those mixins is also available on the {Gems} module, which delegates to a new client.
  #
  # @api public
  module API
    include ActivityEndpoints
    include ApiKeyEndpoints
    include DownloadEndpoints
    include GemEndpoints
    include OwnerEndpoints
    include ProfileEndpoints
    include VersionEndpoints
    include WebHookEndpoints
  end
end
