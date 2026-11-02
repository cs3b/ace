# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "ace/lab/auth/session_attachment"

module Ace
  module Lab
    module Auth
      class SessionAttachmentTest < Minitest::Test
        UNIT = "ace-auth-session-worker-0123456789abcdef.service"
        INVOCATION = "a" * 32

        def setup
          @peer = File.open(File::NULL)
          @main = File.open(File::NULL)
          @identity = SessionPeer::Identity.new(unit: UNIT, invocation_id: INVOCATION, pidfd: @peer, main_pidfd: @main)
          @platform = Object.new
          class << @platform
            attr_accessor :dead_handle
          end
          def @platform.capture(pid) = {"pid" => pid}
          def @platform.pin(_identity) = File.open(File::NULL)
          def @platform.exited?(handle) = handle == dead_handle
          @manager = Object.new
          def @manager.unit_for_pidfd(handle:) = {"unit" => UNIT, "invocation_id" => INVOCATION}
          @command = Object.new
          class << @command
            attr_reader :argv
            def call(argv, timeout:) = (@argv = argv)
          end
        end

        def teardown
          @peer.close
          @main.close
        end

        def attachment
          SessionAttachment.new(identity: @identity, platform: @platform, manager: @manager, command: @command)
        end

        def test_attaches_only_the_child_to_the_verified_unit
          Process.stub(:euid, 0) do
            assert attachment.call(1234)
            assert_equal ["ssau", UNIT, "", "1", "1234"], @command.argv.last(5)
          end
        end

        def test_refuses_a_changed_invocation_before_attaching
          def @manager.unit_for_pidfd(handle:) = {"unit" => UNIT, "invocation_id" => "b" * 32}
          Process.stub(:euid, 0) do
            assert_raises(Error) { attachment.call(1234) }
            assert_nil @command.argv
          end
        end

        def test_refuses_a_changed_invocation_after_attaching
          count = 0
          @manager.define_singleton_method(:unit_for_pidfd) do |handle:|
            count += 1
            {"unit" => UNIT, "invocation_id" => (count <= 2 ? INVOCATION : "b" * 32)}
          end
          Process.stub(:euid, 0) { assert_raises(Error) { attachment.call(1234) } }
          refute_nil @command.argv
        end

        def test_session_verification_refuses_an_exited_main_process
          @platform.dead_handle = @main
          Process.stub(:euid, 0) { assert_raises(Error) { attachment.verify_session! } }
        end
      end
    end
  end
end
