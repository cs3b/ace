# frozen_string_literal: true

require_relative "../test_helper"

class TokenRevokerTest < GitSecretsTestCase
  def setup
    @mock_client = MockApiClient.new
    @revoker = Ace::Git::Secrets::Molecules::TokenRevoker.new(api_client: @mock_client)
  end

  def test_revoke_token_returns_success_for_github_tokens
    token = create_mock_token("github_pat_classic", "ghp_test123456789012345678901234567890AB")

    @mock_client.github_response = {success: true, message: "Token revoked"}

    result = @revoker.revoke_token(token)

    assert result.success?
    assert_equal "github", result.service
    assert_match(/revoked/, result.message.downcase)
  end

  def test_revoke_token_returns_failure_for_failed_github_revocation
    token = create_mock_token("github_pat_classic", "ghp_test123456789012345678901234567890AB")

    @mock_client.github_response = {success: false, message: "Rate limited"}

    result = @revoker.revoke_token(token)

    assert result.failed?
    assert_equal "github", result.service
    assert_match(/rate limited/i, result.message)
  end

  def test_revoke_token_returns_manual_revocation_for_anthropic
    token = create_mock_token("anthropic_api_key", "sk-ant-test123456789012345678901234567890")

    result = @revoker.revoke_token(token)

    assert result.skipped?
    assert_equal "anthropic", result.service
    assert_match(/manual revocation required/i, result.message)
    assert_match(/console\.anthropic\.com/i, result.message)
  end

  def test_revoke_token_returns_manual_revocation_for_openai
    token = create_mock_token("openai_api_key", "sk-test123456789012345678901234567890ABCDEF")

    result = @revoker.revoke_token(token)

    assert result.skipped?
    assert_equal "openai", result.service
    assert_match(/manual revocation required/i, result.message)
  end

  def test_revoke_token_returns_manual_revocation_for_aws
    token = create_mock_token("aws_access_key", "AKIA1234567890ABCDEF")

    result = @revoker.revoke_token(token)

    assert result.skipped?
    assert_equal "aws", result.service
    assert_match(/manual revocation required/i, result.message)
  end

  def test_revoke_token_returns_unsupported_for_unknown_service
    token = create_mock_token("unknown_token", "UNKNOWN_test123456789")

    result = @revoker.revoke_token(token)

    assert result.unsupported?
    assert_match(/does not support automatic revocation/i, result.message)
  end

  def test_revoke_all_revokes_multiple_tokens
    tokens = [
      create_mock_token("github_pat_classic", "ghp_test1234567890123456789012345678901A"),
      create_mock_token("github_pat_classic", "ghp_test1234567890123456789012345678901B")
    ]

    @mock_client.github_response = {success: true, message: "Revoked"}

    results = @revoker.revoke_all(tokens)

    assert_equal 2, results.size
    assert results.all?(&:success?)
  end

  def test_revoke_all_filters_by_service
    tokens = [
      create_mock_token("github_pat_classic", "ghp_test1234567890123456789012345678901A"),
      create_mock_token("anthropic_api_key", "sk-ant-test1234567890123456789012345678901B")
    ]

    @mock_client.github_response = {success: true, message: "Revoked"}

    # Only revoke github tokens
    results = @revoker.revoke_all(tokens, services: ["github"])

    assert_equal 1, results.size
    assert_equal "github", results.first.service
  end

  def test_revoke_all_skips_non_revocable_tokens
    tokens = [
      create_mock_token("unknown_token", "UNKNOWN_test12345678901234567890")
    ]

    results = @revoker.revoke_all(tokens)

    # Unknown tokens have no revocation_service, so they're skipped
    assert_empty results
  end

  def test_revocation_instructions_returns_api_request_for_github
    token = create_mock_token("github_pat_classic", "ghp_test123456789012345678901234567890AB")

    instructions = @revoker.revocation_instructions(token)

    assert_equal :post, instructions[:method]
    assert_match(/credentials\/revoke/, instructions[:url])
    assert_match(/GitHub tokens can be revoked via API/, instructions[:notes])
  end

  def test_revocation_instructions_returns_manual_url_for_anthropic
    token = create_mock_token("anthropic_api_key", "sk-ant-test123456789012345678901234567890")

    instructions = @revoker.revocation_instructions(token)

    assert_equal :manual, instructions[:method]
    assert_match(/console\.anthropic\.com/, instructions[:url])
  end

  private

  def create_mock_token(token_type, raw_value)
    Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: token_type,
      pattern_name: token_type,
      confidence: "high",
      commit_hash: "abc1234",
      file_path: "secret.txt",
      raw_value: raw_value,
      detected_by: "test"
    )
  end

  # Mock API client for testing
  class MockApiClient
    attr_accessor :github_response

    def initialize
      @github_response = {success: true, message: "Mocked"}
    end

    def revoke_github_token(_token)
      github_response
    end

    def build_revocation_request(service, _token)
      case service
      when "github"
        {
          method: :post,
          url: "https://api.github.com/credentials/revoke",
          headers: {"Content-Type" => "application/json"},
          body: {},
          notes: "GitHub tokens can be revoked via API without authentication"
        }
      when "anthropic"
        {
          method: :manual,
          url: "https://console.anthropic.com/settings/keys",
          notes: "Anthropic API keys must be revoked manually via the console"
        }
      when "openai"
        {
          method: :manual,
          url: "https://platform.openai.com/api-keys",
          notes: "OpenAI API keys must be revoked manually via the platform"
        }
      when "aws"
        {
          method: :manual,
          url: "https://console.aws.amazon.com/iam/home#/security_credentials",
          notes: "AWS credentials must be rotated/deleted via IAM console"
        }
      else
        {
          method: :unsupported,
          url: nil,
          notes: "Automatic revocation not supported for #{service}"
        }
      end
    end
  end
end
