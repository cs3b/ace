# frozen_string_literal: true

require_relative "../../test_helper"

class ScanReportTest < GitSecretsTestCase
  def setup
    @scanned_at = Time.new(2025, 12, 21, 10, 30, 15)
  end

  def test_deduplicated_tokens_groups_same_tokens
    # Same token found in multiple commits
    token1 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "abc1234",
      file_path: "config.env",
      line_number: 12
    )
    token2 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "def5678",
      file_path: "config.env",
      line_number: 12
    )
    token3 = create_token(
      raw_value: "ghp_different1234567890abcdefghijAB",
      commit_hash: "ghi9012",
      file_path: ".env",
      line_number: 3
    )

    report = create_report(tokens: [token1, token2, token3])
    deduped = report.deduplicated_tokens

    assert_equal 2, deduped.size
    assert_equal 2, deduped["ghp_duplicate12345678901234567890ABCD"][:locations].size
    assert_equal 1, deduped["ghp_different1234567890abcdefghijAB"][:locations].size
  end

  def test_deduplicated_tokens_collects_all_locations
    token1 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "abc1234",
      file_path: "config.env",
      line_number: 12
    )
    token2 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "def5678",
      file_path: "config.env",
      line_number: 12
    )

    report = create_report(tokens: [token1, token2])
    deduped = report.deduplicated_tokens
    locations = deduped["ghp_duplicate12345678901234567890ABCD"][:locations]

    assert_equal "abc1234", locations[0][:commit]
    assert_equal "def5678", locations[1][:commit]
  end

  def test_to_providers_markdown_returns_nil_for_clean_repo
    report = create_report(tokens: [])
    assert_nil report.to_providers_markdown
  end

  def test_to_providers_markdown_includes_header_with_stats
    token = create_token(token_type: "github_pat_classic")
    report = create_report(tokens: [token])
    markdown = report.to_providers_markdown

    assert_includes markdown, "# Tokens to Revoke"
    assert_includes markdown, "**Scan**: 2025-12-21 10:30:15"
    assert_includes markdown, "**Unique tokens**: 1"
    assert_includes markdown, "**Providers**: 1"
  end

  def test_to_providers_markdown_groups_by_provider
    github_token = create_token(
      token_type: "github_pat_classic",
      raw_value: "ghp_1234567890abcdefghijklmnopqrABCD"
    )
    aws_token = create_token(
      token_type: "aws_access_key",
      raw_value: "AKIAIOSFODNN7EXAMPLE1234567890"
    )

    report = create_report(tokens: [github_token, aws_token])
    markdown = report.to_providers_markdown

    assert_includes markdown, "## GitHub (1 token)"
    assert_includes markdown, "## AWS (1 token)"
  end

  def test_to_providers_markdown_sorts_providers_revocable_first
    manual_token = create_token(
      token_type: "google_api_key",
      raw_value: "AIzaSyA1234567890abcdefghijklmnop"
    )
    github_token = create_token(
      token_type: "github_pat_classic",
      raw_value: "ghp_1234567890abcdefghijklmnopqrABCD"
    )

    report = create_report(tokens: [manual_token, github_token])
    markdown = report.to_providers_markdown

    github_pos = markdown.index("## GitHub")
    manual_pos = markdown.index("## Manual Revocation Required")

    assert github_pos < manual_pos, "Revocable providers should come before manual"
  end

  def test_to_providers_markdown_shows_masked_values
    token = create_token(
      token_type: "github_pat_classic",
      raw_value: "ghp_1234567890abcdefghijklmnopqrABCD"
    )
    report = create_report(tokens: [token])
    markdown = report.to_providers_markdown

    assert_includes markdown, "`ghp_"
    assert_includes markdown, "ABCD`"
    assert_includes markdown, "*"
    refute_includes markdown, "ghp_1234567890abcdefghijklmnopqrABCD"
  end

  def test_to_providers_markdown_lists_all_locations
    token1 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "abc1234567890",
      file_path: "config.env",
      line_number: 12
    )
    token2 = create_token(
      raw_value: "ghp_duplicate12345678901234567890ABCD",
      commit_hash: "def5678901234",
      file_path: ".env",
      line_number: 3
    )

    report = create_report(tokens: [token1, token2])
    markdown = report.to_providers_markdown

    assert_includes markdown, "**Locations:**"
    assert_includes markdown, "`abc1234` config.env:12"
    assert_includes markdown, "`def5678` .env:3"
  end

  def test_save_to_file_generates_providers_report_when_tokens_found
    token = create_token(token_type: "github_pat_classic")
    report = create_report(tokens: [token])

    Dir.mktmpdir do |dir|
      report.save_to_file(directory: dir)

      # Check that both files were created in sessions/ subdirectory
      sessions_dir = File.join(dir, "sessions")
      files = Dir.glob(File.join(sessions_dir, "*"))
      assert_equal 2, files.size

      report_file = files.find { |f| f.end_with?("-report.json") }
      providers_file = files.find { |f| f.end_with?("-providers.md") }

      assert report_file, "Should create report.json"
      assert providers_file, "Should create providers.md"

      # Verify providers file content
      content = File.read(providers_file)
      assert_includes content, "# Tokens to Revoke"
      assert_includes content, "## GitHub"
    end
  end

  def test_save_to_file_skips_providers_report_for_clean_repo
    report = create_report(tokens: [])

    Dir.mktmpdir do |dir|
      report.save_to_file(directory: dir)

      # Files are saved in sessions/ subdirectory
      sessions_dir = File.join(dir, "sessions")
      files = Dir.glob(File.join(sessions_dir, "*"))
      assert_equal 1, files.size
      assert files[0].end_with?("-report.json")
    end
  end

  def test_to_providers_markdown_handles_plural_tokens
    token1 = create_token(
      token_type: "github_pat_classic",
      raw_value: "ghp_1234567890abcdefghijklmnopqrABCD"
    )
    token2 = create_token(
      token_type: "github_oauth",
      raw_value: "gho_5678901234567890abcdefghijklMNOP"
    )

    report = create_report(tokens: [token1, token2])
    markdown = report.to_providers_markdown

    assert_includes markdown, "## GitHub (2 tokens)"
  end

  private

  def create_token(
    token_type: "github_pat_classic",
    raw_value: "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB",
    commit_hash: "abc123def456",
    file_path: "config/secrets.yml",
    line_number: 10
  )
    Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: token_type,
      pattern_name: token_type,
      confidence: "high",
      commit_hash: commit_hash,
      file_path: file_path,
      line_number: line_number,
      raw_value: raw_value
    )
  end

  def create_report(tokens:)
    Ace::Git::Secrets::Models::ScanReport.new(
      tokens: tokens,
      repository_path: "/test/repo",
      scanned_at: @scanned_at,
      commits_scanned: 100,
      detection_method: "ruby_patterns"
    )
  end
end
