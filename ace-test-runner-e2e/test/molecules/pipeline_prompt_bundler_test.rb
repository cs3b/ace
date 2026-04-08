# frozen_string_literal: true

require_relative "../test_helper"

class PipelinePromptBundlerTest < Minitest::Test
  PromptBundler = Ace::Test::EndToEndRunner::Molecules::PipelinePromptBundler
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_prepare_runner_bundles_only_selected_test_cases
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_goal_scenario_files(tmpdir)
      sandbox = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(sandbox)

      bundler = PromptBundler.new
      scenario = build_scenario(scenario_dir)
      output = bundler.prepare_runner(
        scenario: scenario,
        sandbox_path: sandbox,
        test_cases: ["TC-002"]
      )

      assert File.exist?(output[:system_path]), "runner system prompt should be written"
      assert File.exist?(output[:prompt_path]), "runner prompt should be written"

      content = File.read(output[:prompt_path])
      assert_includes content, "Runner Header"
      assert_includes content, "Goal 2"
      refute_includes content, "Goal 1"
      assert_includes content, "Workspace root: #{File.expand_path(sandbox)}"
    end
  end

  def test_prepare_verifier_embeds_artifacts_and_verify_criteria
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_goal_scenario_files(tmpdir)
      sandbox = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(sandbox, "results", "tc", "02"))
      File.write(File.join(sandbox, "results", "tc", "02", "sample.txt"), "artifact body")

      bundler = PromptBundler.new
      scenario = build_scenario(scenario_dir)
      output = bundler.prepare_verifier(
        scenario: scenario,
        sandbox_path: sandbox,
        test_cases: ["TC-002"]
      )

      content = File.read(output[:prompt_path])
      assert_includes content, "Sandbox Artifacts"
      assert_includes content, "results/tc/02/sample.txt"
      assert_includes content, "artifact body"
      assert_includes content, "Verify Header"
      assert_includes content, "Goal 2 verify"
      refute_includes content, "Goal 1 verify"
    end
  end

  def test_prepare_verifier_truncates_large_artifacts
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_goal_scenario_files(tmpdir)
      sandbox = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(sandbox, "results", "tc", "02"))
      File.write(File.join(sandbox, "results", "tc", "02", "large.txt"), "x" * 20_000)

      bundler = PromptBundler.new
      scenario = build_scenario(scenario_dir)
      output = bundler.prepare_verifier(
        scenario: scenario,
        sandbox_path: sandbox,
        test_cases: ["TC-002"]
      )

      content = File.read(output[:prompt_path])
      assert_includes content, "[truncated: original_bytes=20000]"
      assert_includes content, "results/tc/02/large.txt"
    end
  end

  private

  def build_scenario(scenario_dir)
    TestScenario.new(
      test_id: "TS-B36TS-001",
      title: "Pipeline",
      area: "timestamp",
      package: "ace-b36ts",
      file_path: File.join(scenario_dir, "scenario.yml"),
      content: "",
      dir_path: scenario_dir,
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "Goal 1", content: "", file_path: File.join(scenario_dir, "TC-001-one.runner.md"),
          goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Goal 2", content: "", file_path: File.join(scenario_dir, "TC-002-two.runner.md"),
          goal_format: "standalone")
      ]
    )
  end

  def create_goal_scenario_files(tmpdir)
    scenario_dir = File.join(tmpdir, "TS-B36TS-001")
    FileUtils.mkdir_p(scenario_dir)

    File.write(File.join(scenario_dir, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-one.runner.md
          - ./TC-002-two.runner.md
      ---

      # Runner Header
      Workspace root: (current directory)
    MD

    File.write(File.join(scenario_dir, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-one.verify.md
          - ./TC-002-two.verify.md
      ---

      # Verify Header
    MD

    File.write(File.join(scenario_dir, "TC-001-one.runner.md"), "# Goal 1\nrunner one")
    File.write(File.join(scenario_dir, "TC-002-two.runner.md"), "# Goal 2\nrunner two")
    File.write(File.join(scenario_dir, "TC-001-one.verify.md"), "# Goal 1 verify")
    File.write(File.join(scenario_dir, "TC-002-two.verify.md"), "# Goal 2 verify")

    scenario_dir
  end
end
