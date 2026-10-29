# frozen_string_literal: true

require_relative "wake/version"

# ace-wake is an asset package: it carries the Pi harness extension
# (handbook/extensions/ace-wake) through the standard handbook
# projection and the ace-lab installer. There is no Ruby runtime
# behavior beyond the version identity installers and projections
# report.
module Ace
  module Wake
    def self.gem_version
      Gem::Version.new(VERSION)
    end
  end
end
