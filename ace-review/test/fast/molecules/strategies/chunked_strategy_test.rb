# frozen_string_literal: true

require "test_helper"

# Explicitly require the strategy since it's lazy-loaded
require "ace/review/molecules/strategies/chunked_strategy"

class ChunkedStrategyTest < AceReviewTest
  # Use shared temp dir to reduce overhead
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new
  end

  # Helper to create a simple diff block for testing
  def make_diff(path, lines: 10)
    content = ["diff --git a/#{path} b/#{path}"]
    content << "index 1234567..abcdefg 100644"
    content << "--- a/#{path}"
    content << "+++ b/#{path}"
    content << "@@ -1,#{lines} +1,#{lines} @@"
    (lines - 5).times { |i| content << "+line #{i}" }
    content.join("\n") + "\n"
  end

  # can_handle? tests
  def test_can_handle_returns_true_for_valid_diff
    subject = make_diff("lib/foo.rb")
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    assert result
  end

  def test_can_handle_returns_false_for_non_diff_content
    subject = "This is not a diff, just regular text content."
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    refute result
  end

  def test_can_handle_returns_false_for_nil_subject
    result = @strategy.can_handle?(nil, 128_000)

    refute result
  end

  def test_can_handle_returns_false_for_empty_subject
    result = @strategy.can_handle?("", 128_000)

    refute result
  end

  def test_can_handle_returns_false_for_nil_limit
    subject = make_diff("lib/foo.rb")

    result = @strategy.can_handle?(subject, nil)

    refute result
  end

  def test_can_handle_returns_false_for_zero_limit
    subject = make_diff("lib/foo.rb")

    result = @strategy.can_handle?(subject, 0)

    refute result
  end

  def test_can_handle_returns_false_for_negative_limit
    subject = make_diff("lib/foo.rb")

    result = @strategy.can_handle?(subject, -1000)

    refute result
  end

  # prepare tests - basic functionality
  def test_prepare_returns_array
    subject = make_diff("lib/foo.rb")

    result = @strategy.prepare(subject, {})

    assert_kind_of Array, result
  end

  def test_prepare_single_file_returns_single_chunk
    subject = make_diff("lib/foo.rb")

    result = @strategy.prepare(subject, {})

    assert_equal 1, result.length
    assert_equal 0, result[0][:metadata][:chunk_index]
    assert_equal 1, result[0][:metadata][:total_chunks]
    assert_equal ["lib/foo.rb"], result[0][:metadata][:files]
  end

  def test_prepare_includes_strategy_metadata
    subject = make_diff("lib/foo.rb")

    result = @strategy.prepare(subject, {})

    metadata = result[0][:metadata]
    assert_equal :chunked, metadata[:strategy]
    assert_equal 0, metadata[:chunk_index]
    assert_equal 1, metadata[:total_chunks]
    assert_includes metadata[:files], "lib/foo.rb"
  end

  def test_prepare_includes_file_content
    subject = make_diff("lib/foo.rb")

    result = @strategy.prepare(subject, {})

    assert_includes result[0][:content], "diff --git"
    assert_includes result[0][:content], "lib/foo.rb"
  end

  # Summary formatting tests
  def test_prepare_includes_summary_header
    subject = make_diff("lib/foo.rb")
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(include_change_summary: true)

    result = strategy.prepare(subject, {})

    assert_includes result[0][:content], "## Changes Summary"
    assert_includes result[0][:content], "1 files changed"
  end

  def test_prepare_without_summary_when_disabled
    subject = make_diff("lib/foo.rb")
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(include_change_summary: false)

    result = strategy.prepare(subject, {})

    refute_includes result[0][:content], "## Changes Summary"
  end

  def test_prepare_full_summary_for_few_files
    # Create a diff with 5 files (under SUMMARY_THRESHOLD_FULL of 20)
    diffs = (1..5).map { |i| make_diff("lib/file#{i}.rb") }
    subject = diffs.join

    result = @strategy.prepare(subject, {})

    content = result[0][:content]
    assert_includes content, "5 files changed"
    assert_includes content, "`lib/file1.rb`"
    assert_includes content, "`lib/file5.rb`"
    assert_includes content, "[M]"  # Modified marker
  end

  def test_prepare_marks_new_files_correctly
    diff = <<~DIFF
      diff --git a/lib/new_file.rb b/lib/new_file.rb
      new file mode 100644
      index 0000000..abcdefg
      --- /dev/null
      +++ b/lib/new_file.rb
      @@ -0,0 +1,3 @@
      +class NewFile
      +end
    DIFF

    result = @strategy.prepare(diff, {})

    content = result[0][:content]
    assert_includes content, "[A]"  # Added marker
  end

  def test_prepare_marks_deleted_files_correctly
    diff = <<~DIFF
      diff --git a/lib/old_file.rb b/lib/old_file.rb
      deleted file mode 100644
      index abcdefg..0000000
      --- a/lib/old_file.rb
      +++ /dev/null
      @@ -1,3 +0,0 @@
      -class OldFile
      -end
    DIFF

    result = @strategy.prepare(diff, {})

    content = result[0][:content]
    assert_includes content, "[D]"  # Deleted marker
  end

  # Chunking tests
  def test_prepare_splits_large_diffs_into_multiple_chunks
    # Create a strategy with small chunk size to force splitting
    # Minimum available is 1000 tokens, so we need diffs that exceed that
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(
      max_tokens_per_chunk: 1_500,  # Small but above minimum
      include_change_summary: false  # Simplify
    )

    # Create multiple files that together exceed the limit (each ~250 tokens)
    diffs = (1..8).map { |i| make_diff("lib/file#{i}.rb", lines: 100) }
    subject = diffs.join

    result = strategy.prepare(subject, {})

    assert_operator result.length, :>=, 2
    # First chunk
    assert_equal 0, result[0][:metadata][:chunk_index]
    # Last chunk
    assert_equal result.length, result.last[:metadata][:total_chunks]
  end

  def test_prepare_never_splits_within_file
    # Create strategy with chunk size smaller than a single file
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(
      max_tokens_per_chunk: 200,
      include_change_summary: false
    )

    # Create a single file that exceeds chunk size
    # Instead of splitting the file, it should truncate it
    diff = make_diff("lib/large_file.rb", lines: 100)

    result = strategy.prepare(diff, {})

    # Should be single chunk with the file (possibly truncated)
    assert_equal 1, result.length
    assert_includes result[0][:metadata][:files], "lib/large_file.rb"
  end

  def test_prepare_chunk_metadata_tracks_files
    diffs = (1..3).map { |i| make_diff("lib/file#{i}.rb") }
    subject = diffs.join

    result = @strategy.prepare(subject, {})

    # Single chunk should contain all files
    assert_equal 1, result.length
    assert_equal 3, result[0][:metadata][:files].length
    assert_includes result[0][:metadata][:files], "lib/file1.rb"
    assert_includes result[0][:metadata][:files], "lib/file2.rb"
    assert_includes result[0][:metadata][:files], "lib/file3.rb"
  end

  # Overflow handling tests
  def test_prepare_truncates_oversized_files
    # Create strategy with chunk size that forces truncation
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(
      max_tokens_per_chunk: 100,  # Very small
      include_change_summary: false
    )

    diff = make_diff("lib/huge_file.rb", lines: 500)

    result = strategy.prepare(diff, {})

    # Should have truncation marker
    assert_includes result[0][:content], "[TRUNCATED:"
    assert_includes result[0][:content], "lines omitted]"
  end

  def test_prepare_sets_overflow_metadata_for_truncated_files
    # Create strategy that forces truncation
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(
      max_tokens_per_chunk: 100,
      include_change_summary: false
    )

    diff = make_diff("lib/huge_file.rb", lines: 500)

    result = strategy.prepare(diff, {})

    metadata = result[0][:metadata]
    assert metadata[:overflow], "Expected overflow flag to be set"
    assert_kind_of Array, metadata[:overflow_files]
    assert_equal "lib/huge_file.rb", metadata[:overflow_files][0][:path]
    assert_operator metadata[:overflow_files][0][:truncated_lines], :>, 0
  end

  # Edge cases
  def test_prepare_handles_empty_subject
    result = @strategy.prepare("", {})

    assert_equal 1, result.length
    assert_equal "", result[0][:content]
    assert_equal [], result[0][:metadata][:files]
  end

  def test_prepare_handles_nil_subject
    result = @strategy.prepare(nil, {})

    assert_equal 1, result.length
    assert_equal "", result[0][:content]
  end

  def test_prepare_handles_non_diff_content
    subject = "This is not a diff format"

    result = @strategy.prepare(subject, {})

    # Should passthrough as single chunk
    assert_equal 1, result.length
    assert_equal subject, result[0][:content]
    assert_equal [], result[0][:metadata][:files]
  end

  def test_prepare_handles_context_parameter
    subject = make_diff("lib/foo.rb")
    context = {
      system_prompt: "You are a reviewer",
      user_prompt: "Check for bugs",
      model: "gpt-4",
      model_context_limit: 128_000,
      preset: {name: "security"},
      file_list: ["foo.rb", "bar.rb"]
    }

    result = @strategy.prepare(subject, context)

    # Context doesn't modify chunked strategy behavior
    assert_equal 1, result.length
    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  # strategy_name tests
  def test_strategy_name_returns_chunked
    assert_equal :chunked, @strategy.strategy_name
  end

  # Configuration tests
  def test_accepts_config_in_constructor
    config = {max_tokens_per_chunk: 50_000, include_change_summary: false}
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(config)

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end

  # YAML config keys are strings - verify they work
  def test_accepts_string_keyed_config
    # Simulating config loaded from YAML (string keys)
    config = {"max_tokens_per_chunk" => 25_000, "include_change_summary" => false}
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(config)

    # Verify config is honored by checking behavior
    # With a small token limit, a moderately sized diff should be chunked
    subject = make_diff("lib/large_file.rb", lines: 500)
    result = strategy.prepare(subject, {})

    # With 25k tokens, a 500-line file should likely fit in one chunk
    # but we're mainly testing that the config is read
    assert_kind_of Array, result
    refute_empty result

    # Verify include_change_summary: false is honored (no summary in first chunk)
    first_chunk_content = result[0][:content]
    refute_match(/## Changes Summary/, first_chunk_content, "Summary should not be present when disabled via string keys")
  end

  # Edge case: very small max_tokens_per_chunk
  def test_prepare_with_very_small_token_limit_includes_header
    # Use a tiny max_tokens that would normally result in negative available_tokens
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(max_tokens_per_chunk: 100)
    subject = make_diff("lib/foo.rb", lines: 50)

    result = strategy.prepare(subject, {})

    # Should still produce output with at least the header
    assert_equal 1, result.length
    content = result[0][:content]

    # Header lines should be present (diff --git, index, ---, +++)
    assert_match(/diff --git/, content, "Header should include diff --git line")
    assert_match(/--- a\//, content, "Header should include --- line")
    assert_match(/\+\+\+ b\//, content, "Header should include +++ line")
  end

  # Edge case: extended diff header (rename)
  def test_prepare_preserves_extended_header_for_renames
    # Create a diff with extended header (rename)
    extended_diff = <<~DIFF
      diff --git a/old_name.rb b/new_name.rb
      similarity index 95%
      rename from old_name.rb
      rename to new_name.rb
      index 1234567..abcdefg 100644
      --- a/old_name.rb
      +++ b/new_name.rb
      @@ -1,5 +1,5 @@
      -old content
      +new content
      +more new content
      +even more content
    DIFF

    # Use very small chunk size to force truncation
    strategy = Ace::Review::Molecules::Strategies::ChunkedStrategy.new(
      max_tokens_per_chunk: 200,
      include_change_summary: false
    )

    result = strategy.prepare(extended_diff, {})

    content = result[0][:content]

    # Extended header should be preserved
    assert_match(/similarity index/, content, "Extended header should include similarity index")
    assert_match(/rename from/, content, "Extended header should include rename from")
    assert_match(/rename to/, content, "Extended header should include rename to")
    assert_match(/@@/, content, "Header should include hunk marker")
  end

  def test_default_max_tokens
    # Verify the constant exists and is reasonable
    default = Ace::Review::Molecules::Strategies::ChunkedStrategy::DEFAULT_MAX_TOKENS

    assert_equal 100_000, default
  end

  # Factory integration test
  def test_factory_creates_chunked_strategy
    factory = Ace::Review::Molecules::SubjectStrategy
    strategy = factory.for(:chunked)

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end

  def test_factory_creates_chunked_with_config
    factory = Ace::Review::Molecules::SubjectStrategy
    strategy = factory.for(:chunked, max_tokens_per_chunk: 50_000)

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end
end
