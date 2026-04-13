# frozen_string_literal: true

require_relative "../../test_helper"

# Unit tests for HistoryScanner molecule
# Uses mocked gitleaks to avoid slow git operations
class HistoryScannerTest < GitSecretsTestCase
  def setup
    @mock_repo = MockGitRepo.new
  end

  def teardown
    @mock_repo&.cleanup
  end

  def test_scanner_returns_scan_report
    with_mocked_gitleaks(clean: true) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan(min_confidence: "high")

      assert report.is_a?(Ace::Git::Secrets::Models::ScanReport)
      assert report.clean?
      assert_equal [], report.tokens
    end
  end

  def test_scanner_detects_tokens_from_mocked_findings
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::SCAN, confidence: "high"}
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan(min_confidence: "low")

      refute report.clean?
      assert_equal 1, report.tokens.size
      assert_equal TestTokens::SCAN, report.tokens.first.raw_value
    end
  end

  def test_scanner_filters_by_high_confidence
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::HIGH_CONFIDENCE, confidence: "high"},
      {pattern_name: "generic", matched_value: TestTokens::LOW_CONFIDENCE, confidence: "low"}
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan(min_confidence: "high")

      assert_equal 1, report.tokens.size
      assert_equal "high", report.tokens.first.confidence
    end
  end

  def test_scanner_filters_by_medium_confidence
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::HIGH_CONFIDENCE, confidence: "high"},
      {pattern_name: "api-key", matched_value: "sk_medium_test", confidence: "medium"},
      {pattern_name: "generic", matched_value: TestTokens::LOW_CONFIDENCE, confidence: "low"}
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan(min_confidence: "medium")

      assert_equal 2, report.tokens.size
      assert report.tokens.all? { |t| %w[high medium].include?(t.confidence) }
    end
  end

  def test_scanner_applies_file_exclusions
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::SCAN, file_path: "test/fixtures/tokens.json"}
    ]

    exclusions = ["test/**/*"]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path,
        exclusions: exclusions
      )

      report = scanner.scan

      assert report.clean?, "Excluded file should not produce tokens"
      assert_equal 0, report.tokens.size
    end
  end

  def test_scanner_includes_files_not_matching_exclusions
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::SCAN, file_path: "config/secrets.yml"}
    ]

    exclusions = ["test/**/*"]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path,
        exclusions: exclusions
      )

      report = scanner.scan

      refute report.clean?, "Non-excluded file should produce tokens"
      assert_equal 1, report.tokens.size
    end
  end

  def test_scanner_sets_detection_method
    with_mocked_gitleaks(clean: true) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan

      assert_equal "gitleaks", report.detection_method
    end
  end

  def test_scanner_records_scan_options
    with_mocked_gitleaks(clean: true) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan(since: "2020-01-01", min_confidence: "high")

      assert_equal "2020-01-01", report.scan_options[:since]
      assert_equal "high", report.scan_options[:min_confidence]
    end
  end

  def test_scan_files_mode
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::SCAN}
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan_files(min_confidence: "low")

      assert report.is_a?(Ace::Git::Secrets::Models::ScanReport)
      assert_equal 1, report.tokens.size
      assert report.scan_options[:files_only]
    end
  end

  def test_scan_files_sets_commit_hash_to_head
    findings = [
      {pattern_name: "github-pat", matched_value: TestTokens::SCAN, commit_hash: "ignored"}
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan_files

      assert_equal "HEAD", report.tokens.first.commit_hash
    end
  end

  def test_scanner_preserves_token_metadata
    findings = [
      {
        pattern_name: "github-pat",
        token_type: "github_pat_classic",
        matched_value: TestTokens::SCAN,
        file_path: "config.yml",
        line_number: 42,
        commit_hash: "abc1234def",
        confidence: "high"
      }
    ]

    with_mocked_gitleaks(findings: findings) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan

      token = report.tokens.first
      assert_equal "github_pat_classic", token.token_type
      assert_equal "config.yml", token.file_path
      assert_equal 42, token.line_number
      assert_equal "abc1234def", token.commit_hash
      assert_equal "high", token.confidence
      assert_equal "gitleaks", token.detected_by
    end
  end

  def test_scanner_handles_empty_findings
    with_mocked_gitleaks(findings: []) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path
      )

      report = scanner.scan

      assert report.clean?
      assert_equal [], report.tokens
    end
  end

  def test_scanner_accepts_custom_gitleaks_config
    # This test verifies the scanner accepts gitleaks_config parameter
    # The actual config usage is tested in atoms/gitleaks_runner_test.rb
    with_mocked_gitleaks(clean: true) do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @mock_repo.path,
        gitleaks_config: "/path/to/custom.toml"
      )

      # Verify scanner was created successfully with custom config
      report = scanner.scan
      assert report.is_a?(Ace::Git::Secrets::Models::ScanReport)
    end
  end
end
