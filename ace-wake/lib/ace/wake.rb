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

    # Absolute path to the published extension tree
    # (handbook/extensions/ace-wake) inside this package — the single
    # copy projected into .pi/extensions. The one source of truth for
    # cross-package tests that execute the extension's JavaScript; no
    # consumer hardcodes the package layout.
    def self.extension_root
      File.expand_path("../../handbook/extensions/ace-wake", __dir__)
    end
  end
end
