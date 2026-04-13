# frozen_string_literal: true

require "test_helper"
require "ace/git/cli/commands/diff"

class DiffTest < AceGitTestCase
  def setup
    super
    @command = Ace::Git::CLI::Commands::Diff.new
  end

  def test_execute_returns_success_with_valid_range
    # Mock CommandExecutor.in_git_repo? to return true
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      # Mock the orchestrator to return a result
      mock_result = Ace::Git::Models::DiffResult.new(
        content: "diff content",
        files: ["lib/test.rb"],
        stats: {additions: 10, deletions: 5}
      )

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
        output = capture_io do
          result = @command.call(range: "HEAD~1..HEAD", format: "diff")
          assert_equal 0, result
        end
        assert_match(/diff content/, output.first)
      end
    end
  end

  def test_execute_returns_error_when_not_in_git_repo
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, false do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call
      end
      assert_match(/Not a git repository/, error.message)
    end
  end

  def test_execute_returns_no_changes_message_when_diff_empty
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      mock_result = Ace::Git::Models::DiffResult.new(
        content: "",
        files: [],
        stats: {additions: 0, deletions: 0}
      )

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
        output = capture_io do
          result = @command.call(format: "diff")
          assert_equal 0, result
        end
        assert_match(/\(no changes\)/, output.first)
      end
    end
  end

  def test_path_traversal_validation_rejects_dotdot
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      mock_result = Ace::Git::Models::DiffResult.new(
        content: "diff",
        files: [],
        stats: {}
      )

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(output: "../../etc/passwd", format: "diff")
        end
        assert_match(/path traversal not allowed/, error.message)
      end
    end
  end

  def test_config_file_option_loads_yaml
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      # Create a temp config file
      config_content = <<~YAML
        diff:
          exclude_patterns:
            - "*.log"
          exclude_whitespace: false
      YAML

      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "test_config.yml")
        File.write(config_path, config_content)

        mock_result = Ace::Git::Models::DiffResult.new(
          content: "diff",
          files: [],
          stats: {}
        )

        # Verify that the config is loaded and passed
        captured_options = nil
        Ace::Git::Organisms::DiffOrchestrator.stub :generate, ->(opts) {
          captured_options = opts
          mock_result
        } do
          capture_io do
            @command.call(config: config_path, format: "diff")
          end
        end

        # Config loader uses string keys from YAML
        exclude_patterns = captured_options["exclude_patterns"] || captured_options[:exclude_patterns]
        assert_includes exclude_patterns, "*.log"
      end
    end
  end

  def test_config_file_option_raises_on_missing_file
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call(config: "/nonexistent/config.yml", format: "diff")
      end
      assert_match(/Config file not found/, error.message)
    end
  end

  def test_config_file_option_loads_git_rooted_yaml
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      # Create a config file with git: root (standard .ace/git/config.yml format)
      config_content = <<~YAML
        git:
          diff:
            exclude_patterns:
              - "*.log"
              - "vendor/**/*"
            exclude_whitespace: false
      YAML

      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "test_config.yml")
        File.write(config_path, config_content)

        mock_result = Ace::Git::Models::DiffResult.new(
          content: "diff",
          files: [],
          stats: {}
        )

        # Verify that the config is loaded and passed
        captured_options = nil
        Ace::Git::Organisms::DiffOrchestrator.stub :generate, ->(opts) {
          captured_options = opts
          mock_result
        } do
          capture_io do
            @command.call(config: config_path, format: "diff")
          end
        end

        # Config loader uses string keys from YAML
        exclude_patterns = captured_options["exclude_patterns"] || captured_options[:exclude_patterns]
        assert_includes exclude_patterns, "*.log"
        assert_includes exclude_patterns, "vendor/**/*"
      end
    end
  end

  def test_execute_returns_error_for_invalid_git_range
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      # Simulate git error for invalid range
      git_error = Ace::Git::GitError.new("Git command failed: fatal: ambiguous argument 'invalid..range'")

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, ->(_opts) { raise git_error } do
        cli_error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(range: "invalid..range", format: "diff")
        end
        assert_match(/ambiguous argument/, cli_error.message)
      end
    end
  end

  # Regression test for v0.3.2 bug fix: git errors must be propagated, not masked
  # Previously, git errors could be masked as "(no changes)" instead of being reported
  def test_git_errors_are_propagated_not_masked_as_no_changes
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      # Test various git error scenarios that should NOT be masked as "(no changes)"
      error_scenarios = [
        {error: Ace::Git::GitError.new("fatal: bad revision 'nonexistent'"), pattern: /bad revision/},
        {error: Ace::Git::GitError.new("fatal: Not a valid object name"), pattern: /Not a valid object/},
        {error: Ace::Git::GitError.new("fatal: ambiguous argument"), pattern: /ambiguous argument/}
      ]

      error_scenarios.each do |scenario|
        Ace::Git::Organisms::DiffOrchestrator.stub :generate, ->(_opts) { raise scenario[:error] } do
          cli_error = assert_raises(Ace::Support::Cli::Error,
            "Command should raise Cli::Error for: #{scenario[:error].message}") do
            @command.call(range: "some-range", format: "diff")
          end
          assert_match(scenario[:pattern], cli_error.message)
        end
      end
    end
  end

  # Test that output path validation rejects absolute paths outside allowed directories
  def test_output_path_validation_rejects_arbitrary_absolute_paths
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      mock_result = Ace::Git::Models::DiffResult.new(
        content: "diff",
        files: [],
        stats: {}
      )

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(output: "/etc/passwd", format: "diff")
        end
        assert_match(/must be within working directory or temp directory/, error.message)
      end
    end
  end

  def test_grouped_stats_format_uses_grouped_metadata
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      grouped_data = {
        groups: [
          {
            name: "ace-git/",
            additions: 5,
            deletions: 2,
            file_count: 1,
            layers: [
              {
                name: "lib/",
                additions: 5,
                deletions: 2,
                file_count: 1,
                files: [{display_path: "cli/commands/diff.rb", additions: 5, deletions: 2, binary: false}]
              }
            ]
          }
        ],
        total: {additions: 5, deletions: 2, files: 1},
        collapse_above: 5
      }

      mock_result = Ace::Git::Models::DiffResult.new(
        content: "placeholder",
        files: ["ace-git/lib/ace/git/cli/commands/diff.rb"],
        stats: {additions: 5, deletions: 2, total_changes: 7},
        metadata: {grouped_stats: grouped_data}
      )

      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
        output = capture_io do
          result = @command.call(format: "grouped-stats")
          assert_equal 0, result
        end
        assert_match(/ace-git\//, output.first)
        assert_match(/\+5,\s+-2/, output.first)
        refute_match(/🧱 lib\//, output.first)
      end
    end
  end
end
