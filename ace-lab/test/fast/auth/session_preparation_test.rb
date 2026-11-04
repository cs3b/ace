# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_preparation"

module Ace::Lab::Auth
  class SessionPreparationTest < Minitest::Test
    def setup
      @root = Dir.mktmpdir
      @source = File.join(@root, "source.json")
      File.write(@source, JSON.generate("zai" => {"key" => "fixture"}, "other" => {"key" => "excluded"}))
      File.chmod(0o600, @source)
      @runtime = File.join(@root, "runtime")
      Dir.mkdir(@runtime, 0o711)
      @handle = File.open(File::NULL)
      @identity = SessionLauncher::Identity.new(unit: "ace-auth-session-worker-0123456789abcdef.service",
        invocation_id: "a" * 32, process: {"pid" => Process.pid, "uid" => Process.uid, "gid" => Process.gid}, pidfd: @handle)
      @selection = SessionConfiguration::Selection.new(project: "ace", path: "/lab/ace", role: "worker",
        instructions: "/opt/worker.md", gem_home: "/opt/gems", runtime: {"credentials" => @source, "provider" => "zai"})
      @platform = Object.new
      @platform.define_singleton_method(:live!) { |_| true }
      @platform.define_singleton_method(:exited?) { |_| false }
    end

    def teardown
      @handle.close
      FileUtils.remove_entry(@root)
    end

    def builder
      SessionPreparation.new(privileged: true, claim: ->(_) { @runtime }, verify: ->(*) {},
        platform: @platform, owner_uid: Process.uid)
    end

    def test_only_selected_provider_is_projected_into_private_session
      assert_equal @runtime, builder.call(identity: @identity, selection: @selection)
      path = File.join(@runtime, "pi", "auth.json")
      assert_equal({"zai" => {"key" => "fixture"}}, JSON.parse(File.read(path)))
      assert_equal 0o400, File.stat(path).mode & 0o777
      assert_equal Process.uid, File.stat(path).uid
      settings = File.join(@runtime, "pi", "settings.json")
      assert_equal({"defaultProjectTrust" => "never"}, JSON.parse(File.read(settings)))
      assert_equal 0o600, File.stat(settings).mode & 0o777
      %w[home pi].each { |name| assert_equal 0o700, File.stat(File.join(@runtime, name)).mode & 0o777 }
      assert_raises(Error) { builder.call(identity: @identity, selection: @selection) }
      assert_equal({"zai" => {"key" => "fixture"}}, JSON.parse(File.read(path)))
    end

    def test_untrusted_or_malformed_source_never_creates_session_files
      File.chmod(0o644, @source)
      assert_raises(Error) { builder.call(identity: @identity, selection: @selection) }
      assert_empty Dir.children(@runtime)
      File.chmod(0o600, @source)
      File.write(@source, "private malformed fixture")
      error = assert_raises(Error) { builder.call(identity: @identity, selection: @selection) }
      refute_includes error.message, "private malformed"
      assert_empty Dir.children(@runtime)
    end

    def test_unprivileged_preparation_is_refused
      instance = SessionPreparation.new(privileged: false, claim: ->(*) { flunk "claimed" })
      assert_raises(Error) { instance.call(identity: @identity, selection: @selection) }
    end
  end
end
