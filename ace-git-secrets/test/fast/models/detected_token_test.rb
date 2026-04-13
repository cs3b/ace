# frozen_string_literal: true

require_relative "../../test_helper"

class DetectedTokenTest < GitSecretsTestCase
  def test_creates_token_with_required_attributes
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc123def456",
      file_path: "config/secrets.yml",
      raw_value: "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB"
    )

    assert_equal "github_pat_classic", token.token_type
    assert_equal "high", token.confidence
    assert_equal "abc123def456", token.commit_hash
    assert_equal "config/secrets.yml", token.file_path
  end

  def test_masks_token_value
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc123",
      file_path: "test.rb",
      raw_value: "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB"
    )

    masked = token.masked_value
    assert masked.start_with?("ghp_")
    assert masked.end_with?("yzAB")
    assert masked.include?("*")
    refute masked.include?("567890") # middle should be masked
  end

  def test_short_commit
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test",
      pattern_name: "test",
      confidence: "high",
      commit_hash: "abc123def456789",
      file_path: "test.rb",
      raw_value: "secret"
    )

    assert_equal "abc123d", token.short_commit
  end

  def test_high_confidence
    high = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test", pattern_name: "test", confidence: "high",
      commit_hash: "abc", file_path: "test", raw_value: "secret"
    )

    low = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test", pattern_name: "test", confidence: "low",
      commit_hash: "abc", file_path: "test", raw_value: "secret"
    )

    assert high.high_confidence?
    refute low.high_confidence?
  end

  def test_revocation_service_for_github
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "ghp_test"
    )

    assert_equal "github", token.revocation_service
    assert token.revocable?
  end

  def test_revocation_service_for_anthropic
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "anthropic_api_key",
      pattern_name: "anthropic_api_key",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "sk-ant-test"
    )

    assert_equal "anthropic", token.revocation_service
    assert token.revocable?
  end

  def test_revocation_service_for_unknown
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "unknown_token",
      pattern_name: "unknown",
      confidence: "low",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "some_secret"
    )

    assert_nil token.revocation_service
    refute token.revocable?
  end

  def test_to_h_excludes_raw_value_by_default
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test",
      pattern_name: "test",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "secret_value"
    )

    hash = token.to_h
    refute hash.key?(:raw_value)
    assert hash.key?(:masked_value)
  end

  def test_to_h_includes_raw_value_when_requested
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test",
      pattern_name: "test",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "secret_value"
    )

    hash = token.to_h(include_raw: true)
    assert_equal "secret_value", hash[:raw_value]
  end

  def test_rejects_invalid_confidence
    assert_raises(ArgumentError) do
      Ace::Git::Secrets::Models::DetectedToken.new(
        token_type: "test",
        pattern_name: "test",
        confidence: "invalid",
        commit_hash: "abc",
        file_path: "test",
        raw_value: "secret"
      )
    end
  end

  def test_is_frozen
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "test",
      pattern_name: "test",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "secret"
    )

    assert token.frozen?
  end

  def test_provider_name_for_github
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "ghp_test"
    )

    assert_equal "GitHub", token.provider_name
  end

  def test_provider_name_for_aws
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "aws_access_key",
      pattern_name: "aws_access_key",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "AKIAIOSFODNN7EXAMPLE"
    )

    assert_equal "AWS", token.provider_name
  end

  def test_provider_name_for_anthropic
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "anthropic_api_key",
      pattern_name: "anthropic_api_key",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "sk-ant-test"
    )

    assert_equal "Anthropic", token.provider_name
  end

  def test_provider_name_for_openai
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "openai_api_key",
      pattern_name: "openai_api_key",
      confidence: "high",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "sk-test"
    )

    assert_equal "OpenAI", token.provider_name
  end

  def test_provider_name_for_unknown
    token = Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "unknown_token",
      pattern_name: "unknown",
      confidence: "low",
      commit_hash: "abc",
      file_path: "test",
      raw_value: "some_secret"
    )

    assert_equal "Manual Revocation Required", token.provider_name
  end
end
