# frozen_string_literal: true

require "test_helper"

class DiffOrchestratorTest < AceGitTestCase
  def setup
    super
    # Create temp directory first for defensive resource management
    # Ensures @temp_dir is assigned even if later setup fails
    @temp_dir = Dir.mktmpdir

    @orchestrator = Ace::Git::Organisms::DiffOrchestrator
    @mock_config = Ace::Git::Models::DiffConfig.new(
      ranges: ["HEAD~1..HEAD"],
      exclude_patterns: []
    )
    @mock_raw_diff = <<~DIFF
      diff --git a/lib/test.rb b/lib/test.rb
      --- a/lib/test.rb
      +++ b/lib/test.rb
      @@ -1,3 +1,4 @@
       line1
      +line2
       line3
    DIFF
  end

  def teardown
    # Clean up temp directory after tests
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # Consolidated stub helper to avoid repeated stub nesting
  def with_mock_diff_orchestrator(config: @mock_config, diff_content: @mock_raw_diff)
    Ace::Git::Molecules::ConfigLoader.stub :load, config do
      Ace::Git::Molecules::DiffGenerator.stub :generate, diff_content do
        Ace::Git::Molecules::DiffFilter.stub :filter, diff_content do
          yield
        end
      end
    end
  end

  # --- save_to_file tests ---

  def test_save_to_file_writes_content_to_file
    output_path = File.join(@temp_dir, "test.diff")

    with_mock_diff_orchestrator do
      result_path = @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

      assert_equal output_path, result_path
      assert File.exist?(output_path)
      assert_includes File.read(output_path), "line2"
    end
  end

  def test_save_to_file_creates_parent_directories
    output_path = File.join(@temp_dir, "nested", "deep", "test.diff")

    with_mock_diff_orchestrator do
      result_path = @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

      assert File.exist?(output_path)
      assert_equal output_path, result_path
    end
  end

  def test_save_to_file_overwrites_existing_file
    output_path = File.join(@temp_dir, "test.diff")
    File.write(output_path, "old content")

    with_mock_diff_orchestrator do
      @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

      content = File.read(output_path)
      refute_includes content, "old content"
      assert_includes content, "line2"
    end
  end

  # --- save_with_format tests ---

  def test_save_with_format_passes_format_option
    output_path = File.join(@temp_dir, "test.diff")
    captured_options = nil

    mock_generate = ->(options) {
      captured_options = options
      Ace::Git::Models::DiffResult.new(
        content: @mock_raw_diff,
        files: ["lib/test.rb"],
        stats: {}
      )
    }

    @orchestrator.stub :generate, mock_generate do
      @orchestrator.save_with_format(output_path, format: :summary, ranges: ["HEAD~1..HEAD"])

      assert_equal :summary, captured_options[:format]
      assert_equal ["HEAD~1..HEAD"], captured_options[:ranges]
    end
  end

  def test_save_with_format_defaults_to_diff_format
    output_path = File.join(@temp_dir, "test.diff")
    captured_options = nil

    mock_generate = ->(options) {
      captured_options = options
      Ace::Git::Models::DiffResult.new(
        content: @mock_raw_diff,
        files: [],
        stats: {}
      )
    }

    @orchestrator.stub :generate, mock_generate do
      @orchestrator.save_with_format(output_path)

      assert_equal :diff, captured_options[:format]
    end
  end

  def test_save_to_file_writes_empty_diff_result
    output_path = File.join(@temp_dir, "empty.diff")
    empty_config = Ace::Git::Models::DiffConfig.new(
      ranges: ["HEAD..HEAD"],
      exclude_patterns: []
    )

    with_mock_diff_orchestrator(config: empty_config, diff_content: "") do
      @orchestrator.save_to_file(output_path, ranges: ["HEAD..HEAD"])

      assert File.exist?(output_path)
      assert_equal "", File.read(output_path)
    end
  end

  def test_generate_grouped_stats_uses_numstat_and_returns_grouped_output
    grouped_config = Ace::Git::Models::DiffConfig.new(
      ranges: ["HEAD~1..HEAD"],
      exclude_patterns: [],
      format: :grouped_stats
    )

    numstat_output = "7\t2\tace-git/lib/ace/git/cli/commands/diff.rb\n"

    Ace::Git::Molecules::ConfigLoader.stub :load, grouped_config do
      Ace::Git::Molecules::DiffGenerator.stub :generate, @mock_raw_diff do
        Ace::Git::Molecules::DiffFilter.stub :filter, @mock_raw_diff do
          Ace::Git::Molecules::DiffGenerator.stub :generate_numstat, numstat_output do
            result = @orchestrator.generate(format: :grouped_stats, ranges: ["HEAD~1..HEAD"])

            assert_match(/total/, result.content)
            assert_match(/ace-git\//, result.content)
            assert_equal 7, result.stats[:additions]
            assert_equal 2, result.stats[:deletions]
            assert_equal 1, result.stats[:files]
            assert result.metadata[:grouped_stats]
          end
        end
      end
    end
  end
end
