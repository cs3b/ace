# frozen_string_literal: true

require_relative "../test_helper"

class DiffOrchestratorTest < AceGitTestCase
  def setup
    super
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

  # --- save_to_file tests ---

  def test_save_to_file_writes_content_to_file
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "test.diff")

      Ace::Git::Molecules::ConfigLoader.stub :load, @mock_config do
        Ace::Git::Molecules::DiffGenerator.stub :generate, @mock_raw_diff do
          Ace::Git::Molecules::DiffFilter.stub :filter, @mock_raw_diff do
            result_path = @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

            assert_equal output_path, result_path
            assert File.exist?(output_path)
            assert_includes File.read(output_path), "line2"
          end
        end
      end
    end
  end

  def test_save_to_file_creates_parent_directories
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "nested", "deep", "test.diff")

      Ace::Git::Molecules::ConfigLoader.stub :load, @mock_config do
        Ace::Git::Molecules::DiffGenerator.stub :generate, @mock_raw_diff do
          Ace::Git::Molecules::DiffFilter.stub :filter, @mock_raw_diff do
            result_path = @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

            assert File.exist?(output_path)
            assert_equal output_path, result_path
          end
        end
      end
    end
  end

  def test_save_to_file_overwrites_existing_file
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "test.diff")
      File.write(output_path, "old content")

      Ace::Git::Molecules::ConfigLoader.stub :load, @mock_config do
        Ace::Git::Molecules::DiffGenerator.stub :generate, @mock_raw_diff do
          Ace::Git::Molecules::DiffFilter.stub :filter, @mock_raw_diff do
            @orchestrator.save_to_file(output_path, ranges: ["HEAD~1..HEAD"])

            content = File.read(output_path)
            refute_includes content, "old content"
            assert_includes content, "line2"
          end
        end
      end
    end
  end

  # --- save_with_format tests ---

  def test_save_with_format_passes_format_option
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "test.diff")
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
  end

  def test_save_with_format_defaults_to_diff_format
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "test.diff")
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
  end

  def test_save_to_file_writes_empty_diff_result
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "empty.diff")

      empty_config = Ace::Git::Models::DiffConfig.new(
        ranges: ["HEAD..HEAD"],
        exclude_patterns: []
      )

      Ace::Git::Molecules::ConfigLoader.stub :load, empty_config do
        Ace::Git::Molecules::DiffGenerator.stub :generate, "" do
          Ace::Git::Molecules::DiffFilter.stub :filter, "" do
            @orchestrator.save_to_file(output_path, ranges: ["HEAD..HEAD"])

            assert File.exist?(output_path)
            assert_equal "", File.read(output_path)
          end
        end
      end
    end
  end
end
