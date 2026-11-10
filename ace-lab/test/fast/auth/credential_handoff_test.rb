# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "rbconfig"

module Ace
  module Lab
    module Auth
      class CredentialHandoffTest < Minitest::Test
        def test_secret_is_never_written_to_a_world_readable_temporary_file
          Dir.mktmpdir do |dir|
            previous = File.umask(0)
            seen_mode = nil
            secret = Object.new
            secret.define_singleton_method(:to_s) do
              entry = Dir.children(dir).first
              seen_mode = File.stat(File.join(dir, entry)).mode & 0o777 if entry
              "test-token"
            end
            handoff = CredentialHandoff.new(dir, recipient: "worker")
            path = handoff.deliver("lease-test", secret)

            assert_equal 0o600, seen_mode
            assert_equal 0o400, File.stat(path).mode & 0o777
            assert_equal "test-token", File.read(path)
          ensure
            File.umask(previous) if previous
          end
        end

      end
    end
  end
end
