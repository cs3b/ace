# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/session_environment"
require "open3"
require "rbconfig"

class SessionEnvironmentTest < AceOverseerTestCase
  def setup
    super
    @root = Dir.mktmpdir("session-environment")
    @manifest = File.join(@root, "install.yml")
    File.write(@manifest, "{}")
    @auth = File.join(@root, "auth.json")
    write_private(@auth, {"test" => {"type" => "api_key", "key" => "model-secret"}, "other" => {"key" => "unrelated-secret"}})
    @role = File.join(@root, "role.json")
    write_private(@role, "FORGEJO_TOKEN" => "project-token")
    @runtime = File.join(@root, "runtime")
    File.write(@runtime, "#!/bin/sh\nexit 0\n")
    File.chmod(0o700, @runtime)
    @document = {"coordinator" => {"id" => "lab", "path" => "/lab"},
      "projects" => [{"id" => "ace", "path" => "/lab/ace", "environment_files" => {"worker" => @role, "verifier" => @role}}],
      "roles" => %w[worker verifier].map { |role| {"id" => role, "instructions" => "wfi://coworker/#{role}"} },
      "gemset" => {"gem_home" => "/installed/gems"},
      "session_runtime" => {"herdr" => {"socket" => "/tmp/configured-herdr.sock"}, "node" => @runtime, "pi" => @runtime, "provider" => "test", "model" => "local",
        "credentials" => @auth, "path" => ["/installed/bin", "/usr/bin", "/bin"]}}
    @env = {"HOME" => @root, "PATH" => "/wrong/source/bin", "ACE_TOOLCHAIN" => "installed",
      "BUNDLE_GEMFILE" => "/wrong/Gemfile", "ADMIN_TOKEN" => "must-not-leak", "GH_TOKEN" => "must-not-leak"}
    @directories = []
  end

  def teardown
    @directories.each { |path| FileUtils.remove_entry(path) if File.directory?(path) }
    FileUtils.remove_entry(@root)
    super
  end

  def environment
    Ace::Overseer::Molecules::SessionEnvironment.new(env: @env, manifest_path: @manifest, manifest_loader: -> { @document })
  end

  def write_private(path, value)
    File.write(path, JSON.generate(value))
    File.chmod(0o600, path)
  end

  def test_installed_child_receives_only_selected_credentials_and_runtime
    file_path = nil
    environment.with_environment(root: "/lab/ace/.ace-wt/task", role: "worker") do |file, directory, args|
      @directories << directory
      file_path = file
      assert_equal 0o600, File.stat(file).mode & 0o777
      values = JSON.parse(File.read(file))
      assert_equal "installed", values["ACE_TOOLCHAIN"]
      assert_equal "/tmp/configured-herdr.sock", values["HERDR_SOCKET_PATH"]
      assert_equal "/installed/gems", values["GEM_HOME"]
      assert_equal "project-token", values["FORGEJO_TOKEN"]
      refute values.key?("BUNDLE_GEMFILE")
      refute values.key?("GH_TOKEN")
      refute values.key?("ADMIN_TOKEN")
      refute_includes values.fetch("PATH"), "/wrong/source/bin"
      assert_equal ["--model", "test/local"], args
      assert_equal ["test"], JSON.parse(File.read(File.join(directory, "auth.json"))).keys
      out, err, status = Open3.capture3(values, RbConfig.ruby, "-rjson", "-e", "puts JSON.generate(ENV.to_h)", unsetenv_others: true)
      assert status.success?, err
      child = JSON.parse(out)
      assert_equal "project-token", child["FORGEJO_TOKEN"]
      refute child.key?("ADMIN_TOKEN")
    end
    refute File.exist?(file_path)
  end

  def test_logical_review_and_bootstrap_roles_select_explicit_environment_role
    %w[reviewer bootstrap-verifier bootstrap-worker].each do |role|
      environment.with_environment(root: "/lab/ace", role: role) do |file, directory, _|
        @directories << directory
        assert_equal "project-token", JSON.parse(File.read(file))["FORGEJO_TOKEN"]
      end
    end
  end

  def test_missing_executable_or_unsafe_credential_source_refuses_before_launch
    File.chmod(0o600, @runtime)
    assert_raises(Ace::Overseer::Error) { environment.with_environment(root: "/lab/ace", role: "worker") { flunk "launched" } }
    File.chmod(0o700, @runtime)
    File.chmod(0o644, @auth)
    assert_raises(Ace::Overseer::Error) { environment.with_environment(root: "/lab/ace", role: "worker") { flunk "launched" } }
    File.chmod(0o600, @auth)
    write_private(@role, "ACE_TOOLCHAIN" => "auto")
    assert_raises(Ace::Overseer::Error) { environment.with_environment(root: "/lab/ace", role: "worker") { flunk "launched" } }
  end

  def test_missing_manifest_does_not_use_checkout_runtime
    File.unlink(@manifest)
    assert_raises(Ace::Overseer::Error) do
      environment.with_environment(root: "/lab/ace", role: "worker") { flunk "launched" }
    end
  end

  def test_cleanup_removes_auth_but_keeps_session_evidence
    environment.with_environment(root: "/lab/ace", role: "worker") do |_file, directory, _|
      @directories << directory
      File.write(File.join(directory, "transcript.jsonl"), "evidence")
      Ace::Overseer::Molecules::SessionEnvironment.cleanup(directory)
      refute File.exist?(File.join(directory, "auth.json"))
      assert_equal "evidence", File.read(File.join(directory, "transcript.jsonl"))
    end
  end

  def test_cleanup_refuses_arbitrary_same_named_directory
    unrelated = File.join(@root, "ace-session-unrelated")
    Dir.mkdir(unrelated)
    assert_raises(Ace::Overseer::Error) { Ace::Overseer::Molecules::SessionEnvironment.cleanup(unrelated) }
    assert File.directory?(unrelated)
  end
end
