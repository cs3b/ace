# frozen_string_literal: true

require_relative "../test_helper"

class ScenarioParserTest < Minitest::Test
  def setup
    @parser = Ace::Test::EndToEndRunner::Molecules::ScenarioParser.new
  end

  def test_parse_valid_scenario_file
    Dir.mktmpdir do |tmpdir|
      file = create_test_file(tmpdir, "MT-TEST-001-example.mt.md", <<~CONTENT)
        ---
        test-id: MT-TEST-001
        title: Example Test
        area: test
        package: ace-test
        priority: high
        duration: "~10min"
        requires:
          tools: [ruby]
          ruby: ">= 3.0"
        ---

        # Example Test

        ## Objective

        Test something important.

        ## Test Cases

        ### TC-001: First Test
        Check that it works.
      CONTENT

      scenario = @parser.parse(file)
      assert_equal "MT-TEST-001", scenario.test_id
      assert_equal "Example Test", scenario.title
      assert_equal "test", scenario.area
      assert_equal "ace-test", scenario.package
      assert_equal "high", scenario.priority
      assert_equal "~10min", scenario.duration
      assert_equal({ "tools" => ["ruby"], "ruby" => ">= 3.0" }, scenario.requires)
      assert scenario.content.include?("Test something important")
    end
  end

  def test_parse_minimal_frontmatter
    Dir.mktmpdir do |tmpdir|
      file = create_test_file(tmpdir, "MT-TEST-002-minimal.mt.md", <<~CONTENT)
        ---
        test-id: MT-TEST-002
        title: Minimal Test
        area: test
        ---

        # Minimal Test
      CONTENT

      scenario = @parser.parse(file)
      assert_equal "MT-TEST-002", scenario.test_id
      assert_equal "Minimal Test", scenario.title
      assert_equal "medium", scenario.priority  # default
      assert_equal "~5min", scenario.duration    # default
      assert_equal({}, scenario.requires)        # default
    end
  end

  def test_parse_missing_file_raises
    assert_raises(ArgumentError) do
      @parser.parse("/nonexistent/file.mt.md")
    end
  end

  def test_parse_missing_frontmatter_raises
    Dir.mktmpdir do |tmpdir|
      file = create_test_file(tmpdir, "bad.mt.md", "# No frontmatter here\n")
      assert_raises(ArgumentError) { @parser.parse(file) }
    end
  end

  def test_parse_missing_required_fields_raises
    Dir.mktmpdir do |tmpdir|
      file = create_test_file(tmpdir, "missing.mt.md", <<~CONTENT)
        ---
        test-id: MT-TEST-003
        ---

        # Missing required fields
      CONTENT

      error = assert_raises(ArgumentError) { @parser.parse(file) }
      assert_match(/title/, error.message)
      assert_match(/area/, error.message)
    end
  end

  def test_infer_package_from_path
    Dir.mktmpdir do |tmpdir|
      pkg_dir = File.join(tmpdir, "ace-lint", "test", "e2e")
      FileUtils.mkdir_p(pkg_dir)
      file = File.join(pkg_dir, "MT-LINT-001.mt.md")
      File.write(file, <<~CONTENT)
        ---
        test-id: MT-LINT-001
        title: Lint Test
        area: lint
        ---

        # Test
      CONTENT

      scenario = @parser.parse(file)
      assert_equal "ace-lint", scenario.package
    end
  end

  def test_parse_real_e2e_file
    base_dir = File.expand_path("../../..", __dir__)
    lint_test = File.join(base_dir, "ace-lint", "test", "e2e", "MT-LINT-001-ruby-validator-fallback.mt.md")
    skip "Real E2E file not found" unless File.exist?(lint_test)

    scenario = @parser.parse(lint_test)
    assert_equal "MT-LINT-001", scenario.test_id
    assert_equal "ace-lint", scenario.package
    refute_empty scenario.content
  end

  private

  def create_test_file(tmpdir, filename, content)
    path = File.join(tmpdir, filename)
    File.write(path, content)
    path
  end
end
