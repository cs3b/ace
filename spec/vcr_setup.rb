# frozen_string_literal: true

# VCR setup for subprocesses (e.g., when specs spawn CLI helpers or Ruby scripts).
#
# The previous implementation duplicated a pared-down VCR configuration that
# inevitably drifted away from the canonical one used by the RSpec runner
# (`spec/support/vcr.rb`).  Instead of maintaining two separate configs we simply
# load the primary file, guaranteeing identical behaviour (custom matchers,
# sensitive-data filters, recording modes, etc.) in both the parent and child
# processes.

# Ensure Bundler is available inside the subprocess (mirrors old behaviour)
if ENV["BUNDLE_GEMFILE"] && !defined?(Bundler)
  require "bundler/setup"
end

# Load the shared VCR configuration (brings in `vcr`, `webmock/rspec`, matchers,
# filters, RSpec hooks, and recording-mode logic).
require File.expand_path("support/vcr.rb", __dir__)

# `spec/support/vcr.rb` enables WebMock inside an RSpec `before(:suite)` hook,
# which does **not** run in a plain Ruby subprocess. We therefore enable it
# explicitly here to ensure HTTP interception is active.
require "webmock"
WebMock.enable!

# If the parent process provided a cassette name, insert it automatically so the
# subprocess records/replays under the same cassette.
if ENV["VCR_CASSETTE_NAME"] && !VCR.current_cassette
  VCR.insert_cassette(ENV["VCR_CASSETTE_NAME"])
  at_exit { VCR.eject_cassette if VCR.current_cassette }
end
