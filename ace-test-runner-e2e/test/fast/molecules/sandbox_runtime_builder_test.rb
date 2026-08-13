# frozen_string_literal: true

require_relative "../../test_helper"

class SandboxRuntimeBuilderTest < Minitest::Test
  SandboxRuntimeBuilder = Ace::Test::EndToEndRunner::Molecules::SandboxRuntimeBuilder

  FakeStatus = Struct.new(:success?) do
    def exitstatus
      success? ? 0 : 1
    end
  end

  def test_prepare_builds_local_runtime_env_and_rewrites_path_gems
    Dir.mktmpdir do |tmpdir|
      source_root = File.join(tmpdir, "source")
      sandbox_root = File.join(tmpdir, "sandbox")
      build_source_root(source_root)

      calls = []
      ruby_root = File.join(tmpdir, "mise", "ruby", RUBY_VERSION)
      ruby_exec = File.join(ruby_root, "bin", "ruby")
      runner = lambda do |env, *cmd, chdir:|
        calls << {env: env, cmd: cmd, chdir: chdir}

        case cmd
        when ["mise", "where", "ruby@#{RUBY_VERSION}"]
          ["#{ruby_root}\n", "", FakeStatus.new(true)]
        when Array
          if cmd[0] == ruby_exec && cmd[1] == "-e"
            ["", "", FakeStatus.new(true)]
          elsif cmd[0, 3] == [ruby_exec, "-S", "bundle"] && cmd[3] == "install"
            ["installed", "", FakeStatus.new(true)]
          else
            ["", "unexpected command: #{cmd.inspect}", FakeStatus.new(false)]
          end
        end
      end

      builder = SandboxRuntimeBuilder.new(source_root: source_root, command_runner: runner)
      result = builder.prepare(
        sandbox_root: sandbox_root,
        env: {"PATH" => "/usr/bin"},
        tool_names: ["fake-tool"]
      )

      runtime_root = File.join(sandbox_root, ".ace-local", "e2e-runtime")
      gemfile = File.read(File.join(runtime_root, "Gemfile"))
      assert_includes gemfile, %(path: "#{File.join(source_root, "ace-config")}")
      assert_includes gemfile, %(path: "#{File.join(source_root, "ace-handbook")}")

      assert_equal File.join(runtime_root, "Gemfile"), result[:env]["BUNDLE_GEMFILE"]
      assert_equal File.join(runtime_root, "gems"), result[:env]["GEM_HOME"]
      assert_equal File.join(sandbox_root, ".ace"), result[:env]["ACE_CONFIG_PATH"]
      assert_equal runtime_root, result[:env]["ACE_E2E_SANDBOX_RUNTIME_ROOT"]
      assert_includes result[:env]["PATH"].split(File::PATH_SEPARATOR), File.join(runtime_root, "bin")

      assert File.exist?(File.join(runtime_root, "bin", "ace-config"))
      assert File.exist?(File.join(runtime_root, "bin", "ace-handbook"))
      ace_config_shim = File.read(File.join(runtime_root, "bin", "ace-config"))
      assert_includes ace_config_shim, ruby_exec
      assert_includes ace_config_shim, "-rbundler/setup"
      assert File.exist?(File.join(runtime_root, ".bootstrapped"))

      bundle_install_call = calls.find { |entry| entry[:cmd][0, 3] == [ruby_exec, "-S", "bundle"] }
      refute_nil bundle_install_call
      assert_equal runtime_root, bundle_install_call[:chdir]
      assert_equal File.join(runtime_root, "Gemfile"), bundle_install_call[:env]["BUNDLE_GEMFILE"]
    end
  end

  def test_prepare_shared_runtime_builds_cached_runtime_once
    Dir.mktmpdir do |tmpdir|
      source_root = File.join(tmpdir, "source")
      cache_root = File.join(tmpdir, "cache")
      build_source_root(source_root)

      calls = []
      ruby_root = File.join(tmpdir, "mise", "ruby", RUBY_VERSION)
      ruby_exec = File.join(ruby_root, "bin", "ruby")
      runner = lambda do |env, *cmd, chdir:|
        calls << {env: env, cmd: cmd, chdir: chdir}

        case cmd
        when ["mise", "where", "ruby@#{RUBY_VERSION}"]
          ["#{ruby_root}\n", "", FakeStatus.new(true)]
        when Array
          if cmd[0] == ruby_exec && cmd[1] == "-e"
            ["", "", FakeStatus.new(true)]
          elsif cmd[0, 3] == [ruby_exec, "-S", "bundle"] && cmd[3] == "install"
            ["installed", "", FakeStatus.new(true)]
          else
            ["", "unexpected command: #{cmd.inspect}", FakeStatus.new(false)]
          end
        end
      end

      builder = SandboxRuntimeBuilder.new(source_root: source_root, command_runner: runner)
      first_root = builder.prepare_shared_runtime(cache_root: cache_root)
      second_root = builder.prepare_shared_runtime(cache_root: cache_root)

      assert_equal first_root, second_root
      assert File.exist?(File.join(first_root, ".bootstrapped"))
      assert_equal 1, calls.count { |entry| entry[:cmd][0, 3] == [ruby_exec, "-S", "bundle"] }
    end
  end

  def test_prepare_uses_shared_runtime_root_from_env_with_local_mutable_bundler_dirs
    Dir.mktmpdir do |tmpdir|
      source_root = File.join(tmpdir, "source")
      sandbox_root = File.join(tmpdir, "sandbox")
      cache_root = File.join(tmpdir, "cache")
      build_source_root(source_root)

      calls = []
      ruby_root = File.join(tmpdir, "mise", "ruby", RUBY_VERSION)
      ruby_exec = File.join(ruby_root, "bin", "ruby")
      runner = lambda do |env, *cmd, chdir:|
        calls << {env: env, cmd: cmd, chdir: chdir}

        case cmd
        when ["mise", "where", "ruby@#{RUBY_VERSION}"]
          ["#{ruby_root}\n", "", FakeStatus.new(true)]
        when Array
          if cmd[0] == ruby_exec && cmd[1] == "-e"
            ["", "", FakeStatus.new(true)]
          elsif cmd[0, 3] == [ruby_exec, "-S", "bundle"] && cmd[3] == "install"
            ["installed", "", FakeStatus.new(true)]
          else
            ["", "unexpected command: #{cmd.inspect}", FakeStatus.new(false)]
          end
        end
      end

      builder = SandboxRuntimeBuilder.new(source_root: source_root, command_runner: runner)
      shared_root = builder.prepare_shared_runtime(cache_root: cache_root)
      result = builder.prepare(
        sandbox_root: sandbox_root,
        env: {"PATH" => "/usr/bin", "ACE_E2E_SHARED_RUNTIME_ROOT" => shared_root},
        tool_names: ["fake-tool"]
      )

      assert_equal shared_root, result[:runtime_root]
      assert_equal File.join(shared_root, "Gemfile"), result[:env]["BUNDLE_GEMFILE"]
      assert_equal File.join(shared_root, "gems"), result[:env]["GEM_HOME"]
      assert_equal File.join(shared_root, "gems"), result[:env]["GEM_PATH"]
      assert_equal File.join(sandbox_root, ".ace-local", "e2e-runtime", "bundler", "app-config"),
        result[:env]["BUNDLE_APP_CONFIG"]
      assert_equal File.join(sandbox_root, ".ace-local", "e2e-runtime", "bundler", "cache"),
        result[:env]["BUNDLE_USER_CACHE"]
      assert_includes result[:env]["PATH"].split(File::PATH_SEPARATOR), File.join(shared_root, "bin")
      assert_equal 1, calls.count { |entry| entry[:cmd][0, 3] == [ruby_exec, "-S", "bundle"] }
    end
  end

  def test_prepare_rejects_ruby_with_global_ace_gems
    Dir.mktmpdir do |tmpdir|
      source_root = File.join(tmpdir, "source")
      sandbox_root = File.join(tmpdir, "sandbox")
      build_source_root(source_root)
      ruby_root = File.join(tmpdir, "mise", "ruby", RUBY_VERSION)
      ruby_exec = File.join(ruby_root, "bin", "ruby")

      runner = lambda do |_env, *cmd, chdir:|
        case cmd
        when ["mise", "where", "ruby@#{RUBY_VERSION}"]
          ["#{ruby_root}\n", "", FakeStatus.new(true)]
        when Array
          if cmd[0] == ruby_exec && cmd[1] == "-e"
            ["ace-assign\nace-review\n", "", FakeStatus.new(false)]
          else
            ["", "", FakeStatus.new(true)]
          end
        end
      end

      builder = SandboxRuntimeBuilder.new(source_root: source_root, command_runner: runner)
      error = assert_raises(RuntimeError) do
        builder.prepare(sandbox_root: sandbox_root, env: {"PATH" => "/usr/bin"})
      end

      assert_match(/already exposes ace-\* gems globally/, error.message)
      assert_match(/ace-assign/, error.message)
    end
  end

  def test_capture3_does_not_inherit_process_environment
    Dir.mktmpdir do |tmpdir|
      source_root = File.join(tmpdir, "source")
      build_source_root(source_root)
      builder = SandboxRuntimeBuilder.new(source_root: source_root)
      original = ENV["ACE_E2E_LEAK_TEST"]
      ENV["ACE_E2E_LEAK_TEST"] = "leaked"

      stdout, = builder.send(
        :capture3,
        {"HOME" => ENV["HOME"].to_s, "PATH" => ENV["PATH"].to_s},
        "ruby", "-e", "print ENV.fetch(\"ACE_E2E_LEAK_TEST\", \"\")",
        chdir: source_root
      )

      assert_equal "", stdout
    ensure
      if original
        ENV["ACE_E2E_LEAK_TEST"] = original
      else
        ENV.delete("ACE_E2E_LEAK_TEST")
      end
    end
  end

  private

  def build_source_root(source_root)
    FileUtils.mkdir_p(source_root)
    File.write(File.join(source_root, "Gemfile"), <<~RUBY)
      source "https://rubygems.org"

      gem "ace-config", path: "ace-config"
      gem "ace-handbook", path: "./ace-handbook"
      gem "json"
    RUBY
    File.write(File.join(source_root, "Gemfile.lock"), <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          json (2.0.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        json
    LOCK

    FileUtils.mkdir_p(File.join(source_root, "bin"))
    write_executable(File.join(source_root, "bin", "ace-config"))

    handbook_exe = File.join(source_root, "ace-handbook", "exe", "ace-handbook")
    FileUtils.mkdir_p(File.dirname(handbook_exe))
    write_executable(handbook_exe)

    FileUtils.mkdir_p(File.join(source_root, "ace-config"))
    FileUtils.mkdir_p(File.join(source_root, "ace-handbook"))
  end

  def write_executable(path)
    File.write(path, <<~SH)
      #!/usr/bin/env bash
      exit 0
    SH
    FileUtils.chmod(0o755, path)
  end
end
