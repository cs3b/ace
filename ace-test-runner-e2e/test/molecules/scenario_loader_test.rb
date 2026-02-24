# frozen_string_literal: true

require_relative "../test_helper"

class ScenarioLoaderTest < Minitest::Test
  def setup
    @loader = Ace::Test::EndToEndRunner::Molecules::ScenarioLoader.new
  end

  def test_load_valid_scenario
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-LINT-001-validator-fallback",
        scenario_yml: <<~YAML,
          test-id: TS-LINT-001
          title: Ruby Validator Fallback Behavior
          area: lint
          package: ace-lint
          priority: high
          requires:
            tools: [standardrb, rubocop]
          setup:
            - git-init
            - copy-fixtures
            - run: git add -A && git commit -m "initial" --quiet
        YAML
        tc_files: {
          "TC-001-standardrb-present.tc.md" => <<~MD,
            ---
            tc-id: TC-001
            title: StandardRB Used When Present
            ---

            ## Objective
            Verify ace-lint prefers standardrb.
          MD
          "TC-002-rubocop-fallback.tc.md" => <<~MD
            ---
            tc-id: TC-002
            title: Rubocop Fallback When No StandardRB
            ---

            ## Objective
            Verify rubocop is used as fallback.
          MD
        })

      scenario = @loader.load(scenario_dir)

      assert_equal "TS-LINT-001", scenario.test_id
      assert_equal "Ruby Validator Fallback Behavior", scenario.title
      assert_equal "lint", scenario.area
      assert_equal "ace-lint", scenario.package
      assert_equal "high", scenario.priority
      assert_equal({ "tools" => ["standardrb", "rubocop"] }, scenario.requires)
      assert_equal 3, scenario.setup_steps.length
      assert_equal "git-init", scenario.setup_steps[0]
      assert_equal File.expand_path(scenario_dir), scenario.dir_path
      assert_equal 2, scenario.test_cases.length
    end
  end

  def test_load_discovers_tc_files_sorted
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TEST-001-sorting",
        tc_files: {
          "TC-003-third.tc.md" => tc_content("TC-003", "Third"),
          "TC-001-first.tc.md" => tc_content("TC-001", "First"),
          "TC-002-second.tc.md" => tc_content("TC-002", "Second")
        })

      scenario = @loader.load(scenario_dir)
      tc_ids = scenario.test_cases.map(&:tc_id)

      assert_equal ["TC-001", "TC-002", "TC-003"], tc_ids
    end
  end

  def test_load_parses_tc_frontmatter
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TEST-001-parse",
        tc_files: {
          "TC-001-example.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Example Test Case
            ---

            ## Steps
            1. Do something
          MD
        })

      scenario = @loader.load(scenario_dir)
      tc = scenario.test_cases.first

      assert_equal "TC-001", tc.tc_id
      assert_equal "Example Test Case", tc.title
      assert_includes tc.content, "Do something"
      assert tc.file_path.end_with?("TC-001-example.tc.md")
    end
  end

  def test_load_missing_scenario_yml_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = File.join(tmpdir, "TS-EMPTY-001")
      FileUtils.mkdir_p(scenario_dir)

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/scenario\.yml not found/, error.message)
    end
  end

  def test_load_invalid_yaml_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = File.join(tmpdir, "TS-BAD-001")
      FileUtils.mkdir_p(scenario_dir)
      File.write(File.join(scenario_dir, "scenario.yml"), "{ invalid yaml: [")

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Invalid YAML/, error.message)
    end
  end

  def test_load_missing_required_fields_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = File.join(tmpdir, "TS-MISSING-001")
      FileUtils.mkdir_p(scenario_dir)
      File.write(File.join(scenario_dir, "scenario.yml"), <<~YAML)
        test-id: TS-MISSING-001
      YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/title/, error.message)
      assert_match(/area/, error.message)
    end
  end

  def test_load_no_tc_files
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-EMPTY-002", tc_files: {})

      scenario = @loader.load(scenario_dir)
      assert_equal [], scenario.test_cases
    end
  end

  def test_load_with_fixtures_dir
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-FIX-001",
        fixtures: { "valid.rb" => "puts 'ok'" })

      scenario = @loader.load(scenario_dir)
      assert_equal File.expand_path(File.join(scenario_dir, "fixtures")), scenario.fixture_path
    end
  end

  def test_load_without_fixtures_dir
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-NOFIX-001")

      scenario = @loader.load(scenario_dir)
      assert_nil scenario.fixture_path
    end
  end

  def test_load_setup_steps_parsed
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-SETUP-001",
        scenario_yml: <<~YAML)
          test-id: TS-SETUP-001
          title: Setup Steps Test
          area: test
          setup:
            - git-init
            - copy-fixtures
            - run: echo hello
            - write-file:
                path: config.yml
                content: "key: value"
            - env:
                FOO: bar
        YAML

      scenario = @loader.load(scenario_dir)

      assert_equal 5, scenario.setup_steps.length
      assert_equal "git-init", scenario.setup_steps[0]
      assert_equal "copy-fixtures", scenario.setup_steps[1]
      assert_equal({ "run" => "echo hello" }, scenario.setup_steps[2])
      assert_equal({ "write-file" => { "path" => "config.yml", "content" => "key: value" } },
        scenario.setup_steps[3])
      assert_equal({ "env" => { "FOO" => "bar" } }, scenario.setup_steps[4])
    end
  end

  def test_load_parses_pending_from_tc_frontmatter
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TEST-001-pending",
        tc_files: {
          "TC-001-active.tc.md" => <<~MD,
            ---
            tc-id: TC-001
            title: Active Test
            ---

            ## Steps
            1. Do something
          MD
          "TC-002-pending.tc.md" => <<~MD
            ---
            tc-id: TC-002
            title: Pending Test
            pending: "Requires sandbox environment"
            ---

            ## Steps
            1. This can't run yet
          MD
        })

      scenario = @loader.load(scenario_dir)
      assert_equal 2, scenario.test_cases.length

      active_tc = scenario.test_cases.find { |tc| tc.tc_id == "TC-001" }
      pending_tc = scenario.test_cases.find { |tc| tc.tc_id == "TC-002" }

      refute active_tc.pending?
      assert_nil active_tc.pending

      assert pending_tc.pending?
      assert_equal "Requires sandbox environment", pending_tc.pending
    end
  end

  def test_load_parses_tags_mode_execution_model_and_optional_fields
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-META-001",
        scenario_yml: <<~YAML)
          test-id: TS-META-001
          title: Metadata Test
          area: test
          mode: goal
          execution-model: sequential
          tool-under-test: ace-test-e2e
          tags: [Smoke, use-case:Lint, happy-path]
          sandbox-layout:
            output/: "Results"
            cache/: "Cached files"
        YAML

      scenario = @loader.load(scenario_dir)

      assert_equal ["smoke", "use-case:lint", "happy-path"], scenario.tags
      assert_equal "goal", scenario.mode
      assert_equal "sequential", scenario.execution_model
      assert_equal "ace-test-e2e", scenario.tool_under_test
      assert_equal({ "output/" => "Results", "cache/" => "Cached files" }, scenario.sandbox_layout)
    end
  end

  def test_load_invalid_mode_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-BADMODE-001",
        scenario_yml: <<~YAML)
          test-id: TS-BADMODE-001
          title: Invalid Mode
          area: test
          mode: unsupported
        YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Invalid mode/, error.message)
    end
  end

  def test_load_invalid_execution_model_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-BADEXEC-001",
        scenario_yml: <<~YAML)
          test-id: TS-BADEXEC-001
          title: Invalid Execution Model
          area: test
          execution-model: parallel-unbounded
        YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Invalid execution-model/, error.message)
    end
  end

  def test_load_goal_mode_standalone_files
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-GOAL-001",
        scenario_yml: <<~YAML,
          test-id: TS-GOAL-001
          title: Goal Mode
          area: test
          mode: goal
        YAML
        tc_files: {
          "TC-001-first.runner.md" => "# Goal 1 - First\n\nRun first goal.",
          "TC-001-first.verify.md" => "# Goal 1 - First Verify\n\nVerify first goal.",
          "TC-002-second.runner.md" => "# Goal 2 - Second\n\nRun second goal.",
          "TC-002-second.verify.md" => "# Goal 2 - Second Verify\n\nVerify second goal.",
          "runner.yml.md" => "---\ndescription: runner\n---\nRunner config",
          "verifier.yml.md" => "---\ndescription: verifier\n---\nVerifier config"
        })

      scenario = @loader.load(scenario_dir)

      assert_equal ["TC-001", "TC-002"], scenario.test_cases.map(&:tc_id)
      assert_equal "Goal 1 - First", scenario.test_cases.first.title
      assert_equal "goal", scenario.test_cases.first.mode
      assert_equal "standalone", scenario.test_cases.first.goal_format
      assert_includes scenario.test_cases.first.content, "## Runner"
      assert_includes scenario.test_cases.first.content, "## Verifier"
      assert scenario.test_cases.first.file_path.end_with?("TC-001-first.runner.md")
    end
  end

  def test_load_inline_goal_mode_tc_in_procedural_scenario
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-INLINE-GOAL-001",
        scenario_yml: <<~YAML,
          test-id: TS-INLINE-GOAL-001
          title: Inline Goal In Procedural Scenario
          area: test
        YAML
        tc_files: {
          "TC-001-inline-goal.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Inline Goal
            mode: goal
            ---

            ## Objective
            Verify outcome.

            ## Available Tools
            - ace-lint

            ## Success Criteria
            - [ ] Exit code is 0
          MD
        })

      scenario = @loader.load(scenario_dir)
      tc = scenario.test_cases.first
      assert_equal "goal", tc.mode
      assert_equal "inline", tc.goal_format
    end
  end

  def test_load_goal_mode_tc_rejects_steps_section
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-INLINE-GOAL-002",
        scenario_yml: <<~YAML,
          test-id: TS-INLINE-GOAL-002
          title: Inline Goal Reject Steps
          area: test
        YAML
        tc_files: {
          "TC-001-inline-goal.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Inline Goal
            mode: goal
            ---

            ## Objective
            Verify outcome.

            ## Available Tools
            - ace-lint

            ## Success Criteria
            - [ ] Exit code is 0

            ## Steps
            1. Do not allow this
          MD
        })

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/must not include '## Steps'/, error.message)
    end
  end

  def test_load_goal_mode_tc_requires_sections
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-INLINE-GOAL-003",
        scenario_yml: <<~YAML,
          test-id: TS-INLINE-GOAL-003
          title: Inline Goal Missing Sections
          area: test
        YAML
        tc_files: {
          "TC-001-inline-goal.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Inline Goal
            mode: goal
            ---

            ## Objective
            Verify outcome.
          MD
        })

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Goal-mode TC missing required section/, error.message)
    end
  end

  def test_load_goal_mode_tc_invalid_frontmatter_mode_raises
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-INLINE-GOAL-004",
        scenario_yml: <<~YAML,
          test-id: TS-INLINE-GOAL-004
          title: Invalid TC Mode
          area: test
        YAML
        tc_files: {
          "TC-001-inline-goal.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Inline Goal
            mode: unsupported
            ---

            ## Objective
            Verify outcome.
          MD
        })

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Invalid tc mode/, error.message)
    end
  end

  def test_load_goal_mode_standalone_requires_runner_and_verifier_configs
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-GOAL-002",
        scenario_yml: <<~YAML,
          test-id: TS-GOAL-002
          title: Goal Mode Missing Config
          area: test
          mode: goal
        YAML
        tc_files: {
          "TC-001-first.runner.md" => "# Goal 1 - First\n\nRun first goal.",
          "TC-001-first.verify.md" => "# Goal 1 - First Verify\n\nVerify first goal."
        })

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Missing goal-mode file/, error.message)
    end
  end

  def test_infer_package_from_path
    Dir.mktmpdir do |tmpdir|
      pkg_dir = File.join(tmpdir, "ace-lint", "test", "e2e", "TS-LINT-001-test")
      FileUtils.mkdir_p(pkg_dir)
      File.write(File.join(pkg_dir, "scenario.yml"), <<~YAML)
        test-id: TS-LINT-001
        title: Lint Test
        area: lint
      YAML

      scenario = @loader.load(pkg_dir)
      assert_equal "ace-lint", scenario.package
    end
  end

  private

  def create_scenario_dir(tmpdir, name, scenario_yml: nil, tc_files: {}, fixtures: nil)
    scenario_dir = File.join(tmpdir, name)
    FileUtils.mkdir_p(scenario_dir)

    yml = scenario_yml || <<~YAML
      test-id: #{name.split("-")[0..2].join("-")}
      title: Test Scenario
      area: test
      setup:
        - git-init
    YAML
    File.write(File.join(scenario_dir, "scenario.yml"), yml)

    tc_files.each do |filename, content|
      File.write(File.join(scenario_dir, filename), content)
    end

    if fixtures
      fixture_dir = File.join(scenario_dir, "fixtures")
      FileUtils.mkdir_p(fixture_dir)
      fixtures.each do |filename, content|
        File.write(File.join(fixture_dir, filename), content)
      end
    end

    scenario_dir
  end

  def tc_content(tc_id, title)
    <<~MD
      ---
      tc-id: #{tc_id}
      title: #{title}
      ---

      ## Objective
      Test #{title.downcase}.
    MD
  end
end
