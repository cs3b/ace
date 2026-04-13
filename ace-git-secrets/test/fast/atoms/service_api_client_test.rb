# frozen_string_literal: true

require_relative "../../test_helper"

# Conditionally require webmock - only load if available
begin
  require "webmock/minitest"
  WEBMOCK_AVAILABLE = true
rescue LoadError
  WEBMOCK_AVAILABLE = false
end

class ServiceApiClientTest < GitSecretsTestCase
  def setup
    @client = Ace::Git::Secrets::Atoms::ServiceApiClient.new
    WebMock.disable_net_connect! if WEBMOCK_AVAILABLE
  end

  def teardown
    if WEBMOCK_AVAILABLE
      WebMock.reset!
      WebMock.allow_net_connect!
    end
  end

  # Helper to create a client without retry for webmock tests
  # (Faraday retry middleware conflicts with webmock)
  def webmock_client
    Ace::Git::Secrets::Atoms::ServiceApiClient.new(retry_count: 0)
  end

  def test_default_github_revoke_url
    assert_equal "https://api.github.com/credentials/revoke", @client.github_revoke_url
  end

  def test_custom_github_enterprise_url
    client = Ace::Git::Secrets::Atoms::ServiceApiClient.new(
      github_api_url: "https://github.mycompany.com/api/v3"
    )

    assert_equal "https://github.mycompany.com/api/v3/credentials/revoke", client.github_revoke_url
  end

  def test_custom_github_enterprise_url_strips_trailing_slash
    client = Ace::Git::Secrets::Atoms::ServiceApiClient.new(
      github_api_url: "https://github.mycompany.com/api/v3/"
    )

    assert_equal "https://github.mycompany.com/api/v3/credentials/revoke", client.github_revoke_url
  end

  def test_build_revocation_request_github
    request = @client.build_revocation_request("github", "ghp_test_token")

    assert_equal :post, request[:method]
    assert_equal "https://api.github.com/credentials/revoke", request[:url]
    assert_equal({"Content-Type" => "application/json"}, request[:headers])
    assert_equal({credential: "ghp_test_token"}, request[:body])
    assert_match(/GitHub tokens can be revoked via API/, request[:notes])
  end

  def test_build_revocation_request_anthropic
    request = @client.build_revocation_request("anthropic", "sk-ant-test")

    assert_equal :manual, request[:method]
    assert_match(/console\.anthropic\.com/, request[:url])
    assert_match(/manually via the console/, request[:notes])
  end

  def test_build_revocation_request_openai
    request = @client.build_revocation_request("openai", "sk-test")

    assert_equal :manual, request[:method]
    assert_match(/platform\.openai\.com/, request[:url])
    assert_match(/manually via the platform/, request[:notes])
  end

  def test_build_revocation_request_aws
    request = @client.build_revocation_request("aws", "AKIA1234")

    assert_equal :manual, request[:method]
    assert_match(/console\.aws\.amazon\.com/, request[:url])
    assert_match(/IAM console/, request[:notes])
  end

  def test_build_revocation_request_unsupported
    request = @client.build_revocation_request("unknown_service", "some_token")

    assert_equal :unsupported, request[:method]
    assert_nil request[:url]
    assert_match(/not supported/, request[:notes])
  end

  def test_timeout_configuration
    client = Ace::Git::Secrets::Atoms::ServiceApiClient.new(timeout: 60)
    assert_equal 60, client.timeout
  end

  def test_retry_count_configuration
    client = Ace::Git::Secrets::Atoms::ServiceApiClient.new(retry_count: 5)
    assert_equal 5, client.retry_count
  end

  def test_default_timeout
    assert_equal 30, @client.timeout
  end

  def test_default_retry_count
    assert_equal 3, @client.retry_count
  end

  # WebMock-based tests for GitHub API contract
  # These tests verify the actual HTTP behavior against expected API responses

  def test_revoke_github_token_success
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:post, "https://api.github.com/credentials/revoke")
      .with(
        body: {credential: "ghp_test_token_123"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      .to_return(status: 204, body: "")

    result = webmock_client.revoke_github_token("ghp_test_token_123")

    assert result[:success]
    assert_equal "Token revoked successfully", result[:message]
  end

  def test_revoke_github_token_not_found
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:post, "https://api.github.com/credentials/revoke")
      .with(body: {credential: "ghp_nonexistent"}.to_json)
      .to_return(status: 404, body: {message: "Not Found"}.to_json)

    result = webmock_client.revoke_github_token("ghp_nonexistent")

    refute result[:success]
    assert_match(/not found or already revoked/i, result[:message])
  end

  def test_revoke_github_token_invalid_format
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:post, "https://api.github.com/credentials/revoke")
      .with(body: {credential: "invalid"}.to_json)
      .to_return(status: 422, body: {message: "Invalid credential format"}.to_json)

    result = webmock_client.revoke_github_token("invalid")

    refute result[:success]
    assert_match(/invalid.*format/i, result[:message])
  end

  def test_revoke_github_token_rate_limited
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:post, "https://api.github.com/credentials/revoke")
      .with(body: {credential: "ghp_test"}.to_json)
      .to_return(status: 429, body: {message: "Rate limit exceeded"}.to_json)

    result = webmock_client.revoke_github_token("ghp_test")

    refute result[:success]
    assert_match(/rate limit/i, result[:message])
  end

  def test_revoke_github_token_sends_correct_headers
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub = stub_request(:post, "https://api.github.com/credentials/revoke")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "User-Agent" => /ace-git-secrets/
        }
      )
      .to_return(status: 204)

    webmock_client.revoke_github_token("ghp_test")

    assert_requested(stub)
  end

  def test_revoke_github_token_handles_network_error
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:post, "https://api.github.com/credentials/revoke")
      .to_timeout

    result = webmock_client.revoke_github_token("ghp_test")

    refute result[:success]
    assert_match(/error/i, result[:message])
  end

  def test_github_rate_limit_success
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:get, "https://api.github.com/rate_limit")
      .to_return(
        status: 200,
        body: {
          resources: {
            core: {limit: 60, remaining: 45, reset: 1_700_000_000}
          }
        }.to_json
      )

    result = webmock_client.github_rate_limit

    assert_equal 60, result[:limit]
    assert_equal 45, result[:remaining]
    assert_kind_of Time, result[:reset_at]
  end

  def test_github_rate_limit_handles_error
    skip "webmock not available" unless WEBMOCK_AVAILABLE

    stub_request(:get, "https://api.github.com/rate_limit")
      .to_return(status: 500)

    result = webmock_client.github_rate_limit

    # Should return default values on error
    assert_equal 60, result[:limit]
    assert_equal "unknown", result[:remaining]
  end
end
