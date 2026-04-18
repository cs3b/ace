# frozen_string_literal: true

require_relative "../../test_helper"

class BwrapSandboxBackendTest < Minitest::Test
  Backend = Ace::Test::EndToEndRunner::Molecules::BwrapSandboxBackend

  def test_prepared_env_sets_private_runtime_paths
    Dir.mktmpdir do |tmpdir|
      backend = Backend.new(sandbox_root: tmpdir, source_root: "/repo")

      env = backend.prepared_env("CUSTOM" => "value")

      assert_equal File.expand_path(tmpdir), env["PROJECT_ROOT_PATH"]
      assert_equal "/repo", env["ACE_E2E_SOURCE_ROOT"]
      assert_equal "#{File.expand_path(tmpdir)}.support/home", env["HOME"]
      assert_equal "#{File.expand_path(tmpdir)}.support/tmp", env["TMPDIR"]
      assert_equal "#{File.expand_path(tmpdir)}.support/runtime", env["XDG_RUNTIME_DIR"]
      assert_equal "#{File.expand_path(tmpdir)}.support/runtime", env["TMUX_TMPDIR"]
      assert_equal "#{File.expand_path(tmpdir)}.support/bundler/app-config", env["BUNDLE_APP_CONFIG"]
      assert_equal "#{File.expand_path(tmpdir)}.support/bundler/home", env["BUNDLE_USER_HOME"]
      assert_equal "#{File.expand_path(tmpdir)}.support/bundler/cache", env["BUNDLE_USER_CACHE"]
      assert_equal "#{File.expand_path(tmpdir)}.support/bundler/config", env["BUNDLE_USER_CONFIG"]
      assert_equal "#{File.expand_path(tmpdir)}/.ace-local/e2e-runtime/Gemfile", env["BUNDLE_GEMFILE"]
      assert_equal "value", env["CUSTOM"]
    end
  end

  def test_prepared_env_strips_ruby_loader_env_but_keeps_explicit_bundle_env
    Dir.mktmpdir do |tmpdir|
      backend = Backend.new(sandbox_root: tmpdir, source_root: "/repo")

      env = backend.prepared_env(
        "BUNDLE_GEMFILE" => "/repo/Gemfile",
        "BUNDLER_VERSION" => "2.7.2",
        "RUBYOPT" => "-rbundler/setup",
        "RUBYLIB" => "/tmp/lib",
        "KEEP_ME" => "yes"
      )

      assert_equal "/repo/Gemfile", env["BUNDLE_GEMFILE"]
      assert_equal "2.7.2", env["BUNDLER_VERSION"]
      refute env.key?("RUBYOPT")
      refute env.key?("RUBYLIB")
      assert_equal "yes", env["KEEP_ME"]
    end
  end

  def test_prepared_env_preserves_explicit_runtime_bundle_and_gem_paths
    Dir.mktmpdir do |tmpdir|
      backend = Backend.new(sandbox_root: tmpdir, source_root: "/repo")

      env = backend.prepared_env(
        "BUNDLE_GEMFILE" => "/sandbox/Gemfile",
        "BUNDLE_PATH" => "/sandbox/gems",
        "GEM_HOME" => "/sandbox/gems",
        "GEM_PATH" => "/sandbox/gems",
        "ACE_E2E_SANDBOX_RUNTIME_ROOT" => "/sandbox/runtime"
      )

      assert_equal "/sandbox/Gemfile", env["BUNDLE_GEMFILE"]
      assert_equal "/sandbox/gems", env["BUNDLE_PATH"]
      assert_equal "/sandbox/gems", env["GEM_HOME"]
      assert_equal "/sandbox/gems", env["GEM_PATH"]
      assert_equal "/sandbox/runtime", env["ACE_E2E_SANDBOX_RUNTIME_ROOT"]
    end
  end

  def test_command_prefix_mounts_source_root_and_sandbox_root
    Dir.mktmpdir do |tmpdir|
      backend = Backend.new(sandbox_root: tmpdir, source_root: "/repo")
      backend.stub(:ensure_available!, true) do
        prefix = backend.command_prefix(chdir: tmpdir, env: {"PATH" => "/usr/bin"})

        assert_includes prefix, "bwrap"
        assert_includes prefix, "--clearenv"
        assert_includes prefix, "--ro-bind"
        assert_includes prefix, "/repo"
        assert_includes prefix, "--bind"
        assert_includes prefix, File.expand_path(tmpdir)
        assert_includes prefix, "--setenv"
        assert_includes prefix, "HOME"
        assert_equal "--", prefix.last
      end
    end
  end

  def test_command_prefix_mounts_dedicated_ruby_root_when_present
    Dir.mktmpdir do |tmpdir|
      ruby_root = File.join(tmpdir, "ruby-3.4.9")
      FileUtils.mkdir_p(ruby_root)
      backend = Backend.new(sandbox_root: File.join(tmpdir, "sandbox"), source_root: "/repo")

      backend.stub(:ensure_available!, true) do
        prefix = backend.command_prefix(
          chdir: tmpdir,
          env: {
            "PATH" => "/usr/bin",
            "ACE_E2E_SANDBOX_RUBY_ROOT" => ruby_root
          }
        )

        assert_includes prefix, ruby_root
        assert_includes prefix, "ACE_E2E_SANDBOX_RUBY_ROOT"
      end
    end
  end
end
