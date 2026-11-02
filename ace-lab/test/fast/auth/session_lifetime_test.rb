# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_lifetime"

module Ace
  module Lab
    module Auth
      class SessionLifetimeTest < Minitest::Test
        def test_returns_when_the_session_lifetime_descriptor_becomes_ready
          reader, writer = IO.pipe
          writer.close
          assert_equal :session_ended, SessionLifetime.wait(reader, timeout: 1)
        ensure
          reader&.close
          writer&.close unless writer&.closed?
        end

        def test_returns_at_the_deadline_without_polling
          reader, writer = IO.pipe
          assert_equal :expired, SessionLifetime.wait(reader, timeout: 0.01)
        ensure
          reader&.close
          writer&.close
        end

        def test_refuses_invalid_deadlines_or_closed_handles
          reader, writer = IO.pipe
          assert_raises(ArgumentError) { SessionLifetime.wait(reader, timeout: Float::INFINITY) }
          reader.close
          assert_raises(ArgumentError) { SessionLifetime.wait(reader, timeout: 1) }
        ensure
          reader&.close unless reader&.closed?
          writer&.close
        end
      end
    end
  end
end
