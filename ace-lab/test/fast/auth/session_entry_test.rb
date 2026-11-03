# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_entry"

module Ace::Lab::Auth
  class SessionEntryTest < Minitest::Test
    def setup
      @reader, @writer = IO.pipe
      @env = {"ACE_TOOLCHAIN" => "installed", "ACE_LAB_SESSION" => "1"}
      @executed = []
    end

    def teardown
      [@reader, @writer].each { |io| io.close unless io.closed? }
    end

    def run_entry
      SessionEntry.run(["/opt/ace/bin/pi"], input: @reader, environment: @env,
        timeout: 0.2, execute: ->(args) { @executed << args })
    end

    def test_waits_for_complete_release_before_executing
      @writer.write("sta")
      thread = Thread.new { run_entry }
      assert_nil thread.join(0.02)
      assert_empty @executed
      @writer.write("rt\n")
      thread.value
      assert_equal [["/opt/ace/bin/pi"]], @executed
    ensure
      @writer.close unless @writer.closed?
      thread&.join
    end

    def test_eof_and_invalid_release_never_start_agent
      @writer.write("wrong\n")
      assert_raises(Error) { run_entry }
      assert_empty @executed
    end

    def test_channel_closed_before_release_never_starts_agent
      @writer.close
      assert_raises(Error) { run_entry }
      assert_empty @executed
    end

    def test_missing_installed_mode_is_refused
      @env.delete("ACE_TOOLCHAIN")
      assert_raises(Error) { run_entry }
      assert_empty @executed
    end
  end
end
