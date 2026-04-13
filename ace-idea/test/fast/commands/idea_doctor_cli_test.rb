# frozen_string_literal: true

require "test_helper"
require "ace/idea/cli"
require "stringio"

# CLI integration tests for ace-idea doctor command.
class IdeaDoctorCliTest < AceIdeaTestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Idea::IdeaCLI.start(args)
    rescue Ace::Support::Cli::Error => e
      warn e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    {stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code}
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def with_cli_root(root_dir)
    loader = Ace::Idea::Molecules::IdeaConfigLoader
    original_load = loader.method(:load)
    original_root = loader.method(:root_dir)

    loader.define_singleton_method(:load) do |**_opts|
      {"idea" => {"root_dir" => root_dir}}
    end
    loader.define_singleton_method(:root_dir) do |_config = nil|
      root_dir
    end
    yield
  ensure
    loader = Ace::Idea::Molecules::IdeaConfigLoader
    loader.define_singleton_method(:load) { |**opts| original_load.call(**opts) }
    loader.define_singleton_method(:root_dir) { |config = nil| original_root.call(config) }
  end

  # ---------------------------------------------------------------------------
  # basic doctor
  # ---------------------------------------------------------------------------

  def test_doctor_healthy
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "good-idea", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor"])
        assert_equal 0, result[:exit_code], "Expected exit 0: #{result[:stderr]}"
        assert_includes result[:stdout], "Idea Health Check"
        assert_includes result[:stdout], "100/100"
      end
    end
  end

  def test_doctor_with_issues
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-broken")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-broken.idea.s.md"), <<~CONTENT)
        ---
        status: invalid
        title: Broken idea
        ---
      CONTENT

      with_cli_root(root) do
        result = run_cli(["doctor"])
        # Should fail (exit 1) because there are errors
        assert_equal 1, result[:exit_code]
        assert_includes result[:stdout], "Issues Found"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --json
  # ---------------------------------------------------------------------------

  def test_doctor_json_output
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "test-idea", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--json"])
        assert_equal 0, result[:exit_code], result[:stderr]

        parsed = JSON.parse(result[:stdout])
        assert_equal 100, parsed["health_score"]
        assert parsed["valid"]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --quiet
  # ---------------------------------------------------------------------------

  def test_doctor_quiet_healthy
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "good", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--quiet"])
        assert_equal 0, result[:exit_code]
        assert_empty result[:stdout].strip
      end
    end
  end

  def test_doctor_quiet_unhealthy
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-bad")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-bad.idea.s.md"), "---\nstatus: invalid\n---\n")

      with_cli_root(root) do
        result = run_cli(["doctor", "--quiet"])
        assert_equal 1, result[:exit_code]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --check
  # ---------------------------------------------------------------------------

  def test_doctor_check_frontmatter
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--check", "frontmatter"])
        assert_equal 0, result[:exit_code], result[:stderr]
      end
    end
  end

  def test_doctor_check_structure
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--check", "structure"])
        assert_equal 0, result[:exit_code], result[:stderr]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --errors-only
  # ---------------------------------------------------------------------------

  def test_doctor_errors_only
    with_ideas_dir do |root|
      # Create idea that will generate warnings but no errors
      create_idea_fixture(root, id: "abc123", slug: "test", status: "done")
      with_cli_root(root) do
        result = run_cli(["doctor", "--errors-only"])
        assert_equal 0, result[:exit_code]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --auto-fix --dry-run
  # ---------------------------------------------------------------------------

  def test_doctor_auto_fix_dry_run
    with_ideas_dir do |root|
      backup = File.join(root, "old.backup.md")
      File.write(backup, "stale backup content")
      create_idea_fixture(root, id: "abc123", slug: "test", status: "pending", tags: ["test"])

      with_cli_root(root) do
        result = run_cli(["doctor", "--auto-fix", "--dry-run"])
        # File should still exist (dry run)
        assert File.exist?(backup)
        assert_includes result[:stdout], "DRY RUN"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --no-color
  # ---------------------------------------------------------------------------

  def test_doctor_no_color
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--no-color"])
        assert_equal 0, result[:exit_code]
        # Should not contain ANSI escape codes
        refute_match(/\e\[/, result[:stdout])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # help shows doctor
  # ---------------------------------------------------------------------------

  def test_help_lists_doctor_command
    result = run_cli(["help"])
    assert_includes result[:stdout], "doctor"
  end

  # ---------------------------------------------------------------------------
  # nonexistent root
  # ---------------------------------------------------------------------------

  def test_doctor_nonexistent_root
    with_cli_root("/tmp/nonexistent-ideas-#{rand(99999)}") do
      result = run_cli(["doctor"])
      assert_equal 1, result[:exit_code]
      assert_includes result[:stderr], "not found"
    end
  end
end
