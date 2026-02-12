# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"

# Skip all tests on non-macOS platforms
unless RUBY_PLATFORM.include?('darwin')
  # Create a minimal test that skips to satisfy test framework
  class Ace::TestMacClipboardPlatformSkip < Minitest::Test
    def test_skip_on_non_macos
      skip "ace-support-mac-clipboard is macOS only (current platform: #{RUBY_PLATFORM})"
    end
  end
else
  # Only load the module on macOS
  require "ace/support/mac_clipboard"
end