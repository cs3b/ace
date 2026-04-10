# frozen_string_literal: true

require_relative "../test_helper"

class ScenarioLoaderTest < Minitest::Test
  def setup
    @loader = Ace::Test::EndToEndRunner::Molecules::ScenarioLoader.new
  end

  def test_load_valid_standalone_scenario
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
        standalone_tcs: {
          "TC-001-standardrb-present" => {
            runner: "# Goal 1 - StandardRB\n\nRun standardrb path.",
            verify: "# Goal 1 - Verify\n\nVerify standardrb path."
          },
          "TC-002-rubocop-fallback" => {
            runner: "# Goal 2 - Rubocop\n\nRun fallback path.",
            verify: "# Goal 2 - Verify\n\nVerify fallback path."
          }
        })

      scenario = @loader.load(scenario_dir)

      assert_equal "TS-LINT-001", scenario.test_id
      assert_equal "Ruby Validator Fallback Behavior", scenario.title
      assert_equal "lint", scenario.area
      assert_equal "ace-lint", scenario.package
      assert_equal "high", scenario.priority
      assert_equal({"tools" => ["standardrb", "rubocop"]}, scenario.requires)
      assert_equal 3, scenario.setup_steps.length
      assert_equal "git-init", scenario.setup_steps[0]
      assert_equal File.expand_path(scenario_dir), scenario.dir_path
      assert_equal 2, scenario.test_cases.length

      first_tc = scenario.test_cases.first
      assert_equal "TC-001", first_tc.tc_id
      assert_equal "standalone", first_tc.goal_format
      assert_includes first_tc.content, "## Runner"
      assert_includes first_tc.content, "## Verifier"
    end
  end

  def test_load_discovers_standalone_files_sorted
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TEST-001-sorting",
        standalone_tcs: {
          "TC-003-third" => {runner: "# Third", verify: "# Third Verify"},
          "TC-001-first" => {runner: "# First", verify: "# First Verify"},
          "TC-002-second" => {runner: "# Second", verify: "# Second Verify"}
        })

      scenario = @loader.load(scenario_dir)
      tc_ids = scenario.test_cases.map(&:tc_id)

      assert_equal ["TC-001", "TC-002", "TC-003"], tc_ids
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

  def test_load_rejects_legacy_mode_field
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-LEGACY-001",
        scenario_yml: <<~YAML)
          test-id: TS-LEGACY-001
          title: Legacy Mode
          area: test
          mode: goal
        YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Legacy field\(s\) not supported/, error.message)
      assert_match(/mode/, error.message)
    end
  end

  def test_load_rejects_legacy_execution_model_field
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-LEGACY-002",
        scenario_yml: <<~YAML)
          test-id: TS-LEGACY-002
          title: Legacy Execution Model
          area: test
          execution-model: sequential
        YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Legacy field\(s\) not supported/, error.message)
      assert_match(/execution-model/, error.message)
    end
  end

  def test_load_rejects_inline_tc_files
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-INLINE-001",
        inline_tcs: {
          "TC-001-inline.tc.md" => <<~MD
            ---
            tc-id: TC-001
            title: Inline
            ---

            ## Steps
            1. Unsupported format
          MD
        })

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Inline TC files are no longer supported/, error.message)
    end
  end

  def test_load_no_tc_files
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-EMPTY-002")

      scenario = @loader.load(scenario_dir)
      assert_equal [], scenario.test_cases
    end
  end

  def test_load_with_fixtures_dir
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-FIX-001",
        fixtures: {"valid.rb" => "puts 'ok'"})

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
            - agent-env:
                FOO: bar
        YAML

      scenario = @loader.load(scenario_dir)

      assert_equal 5, scenario.setup_steps.length
      assert_equal "git-init", scenario.setup_steps[0]
      assert_equal "copy-fixtures", scenario.setup_steps[1]
      assert_equal({"run" => "echo hello"}, scenario.setup_steps[2])
      assert_equal({"write-file" => {"path" => "config.yml", "content" => "key: value"}},
        scenario.setup_steps[3])
      assert_equal({"agent-env" => {"FOO" => "bar"}}, scenario.setup_steps[4])
    end
  end

  def test_load_parses_tags_and_optional_fields
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-META-001",
        scenario_yml: <<~YAML)
          test-id: TS-META-001
          title: Metadata Test
          area: test
          tool-under-test: ace-test-e2e
          tags: [Smoke, use-case:Lint, happy-path]
          sandbox-layout:
            output/: "Results"
            cache/: "Cached files"
        YAML

      scenario = @loader.load(scenario_dir)

      assert_equal ["smoke", "use-case:lint", "happy-path"], scenario.tags
      assert_equal "ace-test-e2e", scenario.tool_under_test
      assert_equal({"output/" => "Results", "cache/" => "Cached files"}, scenario.sandbox_layout)
    end
  end

  def test_load_with_timeout_override
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TIMEOUT-001",
        scenario_yml: <<~YAML)
          test-id: TS-TIMEOUT-001
          title: Timeout Scenario
          area: test
          timeout: 900
        YAML

      scenario = @loader.load(scenario_dir)

      assert_equal 900, scenario.timeout
    end
  end

  def test_load_rejects_invalid_timeout
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-TIMEOUT-002",
        scenario_yml: <<~YAML)
          test-id: TS-TIMEOUT-002
          title: Bad Timeout Scenario
          area: test
          timeout: sixty
        YAML

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Invalid timeout/, error.message)
    end
  end

  def test_load_standalone_requires_runner_and_verifier_configs
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-PAIR-001",
        standalone_tcs: {
          "TC-001-first" => {runner: "# Goal 1", verify: "# Verify 1"}
        },
        include_runner_config: false)

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Missing standalone file/, error.message)
      assert_match(/runner\.yml\.md/, error.message)
    end
  end

  def test_load_standalone_requires_matching_pairs
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-PAIR-002",
        standalone_tcs: {
          "TC-001-first" => {runner: "# Goal 1", verify: "# Verify 1"}
        })
      FileUtils.rm_f(File.join(scenario_dir, "TC-001-first.verify.md"))

      error = assert_raises(ArgumentError) { @loader.load(scenario_dir) }
      assert_match(/Missing standalone verify file/, error.message)
    end
  end

  def test_load_ignores_sandbox_setup_field
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_scenario_dir(tmpdir, "TS-SETUP-002",
        scenario_yml: <<~YAML)
          test-id: TS-SETUP-002
          title: Sandbox Setup Test
          area: test
          sandbox-setup:
            - "mise trust mise.toml"
        YAML

      scenario = @loader.load(scenario_dir)

      refute_respond_to scenario, :sandbox_setup
      refute_respond_to scenario, :sandbox_teardown
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

  def create_scenario_dir(tmpdir, name, scenario_yml: nil, standalone_tcs: {}, inline_tcs: {}, fixtures: nil,
    include_runner_config: true, include_verifier_config: true)
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

    if include_runner_config
      File.write(File.join(scenario_dir, "runner.yml.md"), <<~MD)
        ---
        bundle:
          files: []
        ---

        # Runner Config
      MD
    end

    if include_verifier_config
      File.write(File.join(scenario_dir, "verifier.yml.md"), <<~MD)
        ---
        bundle:
          files: []
        ---

        # Verifier Config
      MD
    end

    standalone_tcs.each do |basename, parts|
      File.write(File.join(scenario_dir, "#{basename}.runner.md"), parts.fetch(:runner))
      File.write(File.join(scenario_dir, "#{basename}.verify.md"), parts.fetch(:verify))
    end

    inline_tcs.each do |filename, content|
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
end
