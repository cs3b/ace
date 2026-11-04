# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_entry"

module Ace::Lab::Auth
  class SessionEntryTest < Minitest::Test
    def setup
      @reader, @writer = IO.pipe
      @env = {"ACE_TOOLCHAIN" => "installed", "ACE_LAB_SESSION" => "1"}
      @executed = []
      @root = File.realpath(Dir.mktmpdir)
      @directory = File.join(@root, "project")
    end

    def teardown
      [@reader, @writer].each { |io| io.close unless io.closed? }
      FileUtils.remove_entry(@root)
    end

    def run_entry
      SessionEntry.run(["/opt/ace/bin/pi"], directory: @directory, input: @reader, environment: @env,
        timeout: 0.2, execute: ->(args) { @observed_directory = Dir.pwd; @executed << args })
    end

    def test_waits_for_complete_release_before_executing
      @writer.write("sta")
      thread = Thread.new { run_entry }
      assert_nil thread.join(0.02)
      assert_empty @executed
      Dir.mkdir(@directory)
      @writer.write("rt\n")
      thread.value
      assert_equal [["/opt/ace/bin/pi"]], @executed
      assert_equal @directory, @observed_directory
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

    def test_missing_or_redirected_directory_never_starts_agent
      @writer.write("start\n")
      assert_raises(Errno::ENOENT) { run_entry }
      File.symlink(@root, @directory)
      @writer.write("start\n")
      assert_raises(Error) { run_entry }
      assert_empty @executed
    end
  end
end
