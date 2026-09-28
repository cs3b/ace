# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "tmpdir"
require "fileutils"

# Command-level hermetic regression coverage (SC1/SC2).
#
# Real probe packages are executed through the ace-test and ace-test-suite
# entrypoints under a clean parent environment and a poisoned one (ambient
# LAB_*/ACE_* runtime configuration, provider credentials, proxy and bundler
# project selection, hostile HOME). Results, fixture endpoint selection and
# fixture-owned HOME must be identical, and the invoking environment must
# never be mutated.
class HermeticEnvironmentTest < Minitest::Test
  PROBE_ENDPOINT = "http://127.0.0.1:1"

  def setup
    @original_dir = Dir.pwd
    @package_root = File.expand_path("../..", __dir__)
    @runner_lib = File.join(@package_root, "lib")
    @runner_exe_dir = File.join(@package_root, "exe")
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
  end

  def test_package_run_is_hermetic_under_clean_and_poisoned_parent_environments
    Dir.mktmpdir do |root|
      probe = build_probe_package(root, "probe-serial")
      env_before = ENV.to_h

      clean_output, clean_status = spawn_ace_test(clean_env, probe, "all")
      clean_home = read_probe_home(probe)

      poison_output, poison_status = spawn_ace_test(poisoned_env, probe, "all")
      poison_home = read_probe_home(probe)

      assert clean_status.success?, "clean-env run failed:\n#{clean_output}"
      assert poison_status.success?, "poisoned-env run failed:\n#{poison_output}"

      assert_equal env_before, ENV.to_h, "invoking environment was mutated"

      [clean_output, poison_output].each do |output|
        assert_includes output, "Test mode: deterministic (hermetic environment)"
      end

      [clean_home, poison_home].each do |home|
        assert home.start_with?(Dir.tmpdir), "fixture home escaped test-owned temp: #{home}"
      end
      refute_equal clean_home, poison_home, "fixture home was reused across runs"
    end
  end

  def test_in_process_execution_is_hermetic_under_poisoned_environment
    Dir.mktmpdir do |root|
      probe = build_probe_package(root, "probe-direct")

      output, status = spawn_ace_test(poisoned_env, probe, "all", "--direct")

      assert status.success?, "in-process run failed:\n#{output}"
      assert_includes output, "0 failures"
      home = read_probe_home(probe)
      assert home.start_with?(Dir.tmpdir), "fixture home escaped test-owned temp: #{home}"
    end
  end

  def test_suite_runs_parallel_packages_with_distinct_hermetic_fixture_homes
    Dir.mktmpdir do |root|
      probe_a = build_probe_package(root, "probe-a")
      probe_b = build_probe_package(root, "probe-b")
      write_suite_config(root, [probe_a, probe_b])

      env = poisoned_env

      stdout, stderr, status = Open3.capture3(
        env, RbConfig.ruby, "-I", @runner_lib, File.join(@runner_exe_dir, "ace-test-suite"),
        chdir: root, unsetenv_others: true
      )
      output = stdout + stderr

      assert status.success?, "suite run failed:\n#{output}"
      assert_includes output, "Test mode: deterministic (hermetic environment)"

      home_a = read_probe_home(probe_a)
      home_b = read_probe_home(probe_b)
      [home_a, home_b].each do |home|
        assert home.start_with?(Dir.tmpdir), "fixture home escaped test-owned temp: #{home}"
      end
      refute_equal home_a, home_b, "parallel packages shared one fixture home"
    end
  end

  def test_missing_required_fixture_configuration_is_a_setup_error_naming_the_key
    Dir.mktmpdir do |root|
      probe = build_probe_package(root, "probe-required", require_missing_token: true)

      output, status = spawn_ace_test(clean_env, probe, "all")

      refute status.success?, "run without required fixture configuration must fail:\n#{output}"
      assert_includes output, "Missing required fixture environment"
      assert_includes output, "PROBE_TOKEN"
      refute_includes output, "super-secret-value"
    end
  end

  private

  def clean_env
    {
      "PATH" => ENV["PATH"],
      "LANG" => ENV["LANG"],
      "TMPDIR" => Dir.tmpdir
    }
  end

  def poisoned_env
    # Ambient poison must stay runner-boot survivable: a broken ambient
    # BUNDLE_GEMFILE or RUBYOPT prevents any Ruby tooling from booting and is
    # the invoking shell's problem, not a test-isolation concern. Child-level
    # blocking of those keys is locked by EnvironmentPolicy unit tests.
    clean_env.merge(
      "HOME" => "/nonexistent/hermetic-home",
      "LAB_SOCKET" => "/tmp/lab-poison.sock",
      "LAB_HITL_STORE" => "/tmp/lab-poison-store",
      "ACE_RUNTIME_ENDPOINT" => "http://10.9.8.7:9999",
      "ACE_ASSIGN_ID" => "poison-assignment",
      "ANTHROPIC_API_KEY" => "poison-key",
      "HTTP_PROXY" => "http://10.9.8.7:1"
    )
  end

  # Spawn the ace-test entrypoint from this source tree with an explicit
  # environment (no bundler context of the invoking process).
  def spawn_ace_test(env, probe, *args)
    stdout, stderr, status = Open3.capture3(
      env, RbConfig.ruby, "-I", @runner_lib, File.join(@runner_exe_dir, "ace-test"), probe, *args
    )
    [stdout + stderr, status]
  end

  def build_probe_package(root, name, require_missing_token: false)
    package = File.join(root, name)
    FileUtils.mkdir_p(File.join(package, "test", "atoms"))
    FileUtils.mkdir_p(File.join(package, ".ace", "test"))

    File.write(File.join(package, "Gemfile"), <<~GEM)
      source "https://rubygems.org"
      gem "minitest"
    GEM

    File.write(File.join(package, ".ace", "test", "runner.yml"), probe_runner_config(require_missing_token))

    File.write(File.join(package, "test", "atoms", "probe_test.rb"), <<~RUBY)
      require "minitest/autorun"

      class ProbeHermeticEnvTest < Minitest::Test
        def test_environment_is_hermetic
          File.write("probe_home.txt", ENV["HOME"].to_s)

          refute ENV.keys.any? { |key| key.start_with?("LAB_", "ACE_") },
            "ambient Lab/ACE configuration leaked: \#{ENV.keys.grep(/^(LAB|ACE)_/).join(", ")}"
          refute ENV.key?("ANTHROPIC_API_KEY"), "provider credentials leaked to tests"
          refute ENV.key?("HTTP_PROXY"), "proxy selection leaked to tests"
          refute_equal "/nonexistent/Gemfile", ENV["BUNDLE_GEMFILE"].to_s,
            "bundler project selection leaked to tests"
          assert ENV["HOME"].start_with?(Dir.tmpdir), "HOME is not fixture-owned: \#{ENV["HOME"]}"
          assert_equal "#{PROBE_ENDPOINT}", ENV["PROBE_ENDPOINT"], "fixture override missing"
        end
      end
    RUBY

    install_env = {
      "PATH" => ENV["PATH"],
      "HOME" => ENV["HOME"],
      "TMPDIR" => Dir.tmpdir
    }
    install_output, install_status = Open3.capture2e(
      install_env, "bundle", "install", "--local", chdir: package, unsetenv_others: true
    )
    assert install_status.success?, "bundle install for probe #{name} failed:\n#{install_output}"

    package
  end

  def probe_runner_config(require_missing_token)
    if require_missing_token
      <<~YAML
        version: 1
        environment:
          require: [PROBE_TOKEN]
      YAML
    else
      <<~YAML
        version: 1
        environment:
          overrides:
            PROBE_ENDPOINT: "#{PROBE_ENDPOINT}"
          require: [PROBE_ENDPOINT]
      YAML
    end
  end

  def write_suite_config(root, probe_paths)
    FileUtils.mkdir_p(File.join(root, ".ace", "test"))
    package_lines = probe_paths.each_with_index.flat_map do |path, index|
      name = index.zero? ? "probe-a" : "probe-b"
      ["    - name: #{name}", "      path: #{path}", "      priority: #{index + 1}"]
    end

    yaml = [
      "test_suite:",
      "  max_parallel: 2",
      "  packages:",
      *package_lines,
      "  test_options:",
      "    format: progress",
      "    save_reports: true",
      "    report_dir: reports"
    ].join("\n")
    File.write(File.join(root, ".ace", "test", "suite.yml"), yaml + "\n")
  end

  def read_probe_home(probe)
    File.read(File.join(probe, "probe_home.txt"))
  end
end
