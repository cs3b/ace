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
