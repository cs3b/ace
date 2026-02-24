# frozen_string_literal: true

require "open3"
require_relative "../test_helper"

class PipelineSandboxBuilderTest < Minitest::Test
  SandboxBuilder = Ace::Test::EndToEndRunner::Molecules::PipelineSandboxBuilder
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_build_creates_required_layout_and_provider_link
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, 'bin')}:#{original_path}"

      builder = SandboxBuilder.new(config_root: project_root)
      env = builder.build(
        scenario: build_scenario(tmpdir),
        sandbox_path: sandbox_path
      )

      assert Dir.exist?(File.join(sandbox_path, ".git")), "sandbox should be git repo"
      assert File.exist?(File.join(sandbox_path, "mise.toml")), "sandbox should include mise.toml"
      assert mise_config_trusted?(sandbox_path), "mise.toml should be trusted"
      assert File.symlink?(File.join(sandbox_path, ".ace", "llm", "providers")), "providers should be symlinked"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "01")), "result dir 01 should exist"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "02")), "result dir 02 should exist"
      assert_equal File.expand_path(sandbox_path), env["PROJECT_ROOT_PATH"]
    ensure
      ENV["PATH"] = original_path
    end
  end

  def test_build_executes_sandbox_setup_commands
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, 'bin')}:#{original_path}"

      scenario = build_scenario(tmpdir, sandbox_setup: ["touch $SANDBOX_PATH/marker.txt"])
      builder = SandboxBuilder.new(config_root: project_root)
      builder.build(scenario: scenario, sandbox_path: sandbox_path)

      assert File.exist?(File.join(sandbox_path, "marker.txt")), "sandbox setup command should have created marker.txt"
    ensure
      ENV["PATH"] = original_path
    end
  end

  def test_build_raises_on_sandbox_setup_failure
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, 'bin')}:#{original_path}"

      scenario = build_scenario(tmpdir, sandbox_setup: ["exit 1"])
      builder = SandboxBuilder.new(config_root: project_root)

      error = assert_raises(RuntimeError) do
        builder.build(scenario: scenario, sandbox_path: sandbox_path)
      end
      assert_match(/Sandbox setup command failed/, error.message)
      assert_match(/exit 1/, error.message)
    ensure
      ENV["PATH"] = original_path
    end
  end

  def test_build_provides_env_vars_to_sandbox_setup
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, 'bin')}:#{original_path}"

      # Verify SANDBOX_PATH env var (not PROJECT_ROOT_PATH, which mise overrides in login shells)
      scenario = build_scenario(tmpdir, sandbox_setup: ["echo $SANDBOX_PATH > $SANDBOX_PATH/sandbox_env.txt"])
      builder = SandboxBuilder.new(config_root: project_root)
      builder.build(scenario: scenario, sandbox_path: sandbox_path)

      env_file = File.join(sandbox_path, "sandbox_env.txt")
      assert File.exist?(env_file), "sandbox setup should have written sandbox_env.txt"
      assert_equal File.expand_path(sandbox_path), File.read(env_file).strip
    ensure
      ENV["PATH"] = original_path
    end
  end

  private

  def build_scenario(tmpdir, sandbox_setup: ["mise trust $SANDBOX_PATH/mise.toml"])
    TestScenario.new(
      test_id: "TS-TEST-001",
      title: "Goal",
      area: "test",
      package: "ace-test",
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      tool_under_test: "fake-tool",
      sandbox_layout: {
        "results/tc/01/" => "first",
        "results/tc/02/" => "second"
      },
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "One", content: "", file_path: "one.runner.md", goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Two", content: "", file_path: "two.runner.md", goal_format: "standalone")
      ],
      sandbox_setup: sandbox_setup
    )
  end

  def mise_config_trusted?(sandbox_path)
    stdout, _stderr, status = Open3.capture3("mise", "trust", "--show", chdir: sandbox_path)
    return false unless status.success?

    stdout.include?("trusted")
  end

  def write_fake_tool(bin_dir, name)
    path = File.join(bin_dir, name)
    File.write(path, <<~SH)
      #!/usr/bin/env bash
      if [ "$1" = "--help" ]; then
        echo "help ok"
        exit 0
      fi
      exit 1
    SH
    FileUtils.chmod(0o755, path)
  end
end
