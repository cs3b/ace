# frozen_string_literal: true

require_relative "../test_helper"

class GoalModeSandboxBuilderTest < Minitest::Test
  SandboxBuilder = Ace::Test::EndToEndRunner::Molecules::GoalModeSandboxBuilder
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
      assert File.symlink?(File.join(sandbox_path, ".ace", "llm", "providers")), "providers should be symlinked"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "01")), "result dir 01 should exist"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "02")), "result dir 02 should exist"
      assert_equal File.expand_path(sandbox_path), env["PROJECT_ROOT_PATH"]
    ensure
      ENV["PATH"] = original_path
    end
  end

  private

  def build_scenario(tmpdir)
    TestScenario.new(
      test_id: "TS-TEST-001",
      title: "Goal",
      area: "test",
      package: "ace-test",
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      mode: "goal",
      tool_under_test: "fake-tool",
      sandbox_layout: {
        "results/tc/01/" => "first",
        "results/tc/02/" => "second"
      },
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "One", content: "", file_path: "one.runner.md", mode: "goal", goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Two", content: "", file_path: "two.runner.md", mode: "goal", goal_format: "standalone")
      ]
    )
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
