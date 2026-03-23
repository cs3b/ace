# frozen_string_literal: true

require_relative "../test_helper"

class RevokeCommandTest < GitSecretsTestCase
  def setup
    # Use mock repo for fast tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
    @original_dir = Dir.pwd
    Dir.chdir(@mock_repo.path)
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    @mock_repo&.cleanup
  end

  def test_returns_success_when_no_tokens_found
    @mock_repo.add_file("clean.txt", "no secrets here")

    # Mock gitleaks to return no findings
    with_mocked_gitleaks(clean: true) do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute({})
        assert_equal 0, exit_code
      end

      assert_match(/No tokens found to revoke/i, output)
    end
  end

  def test_displays_revocation_results
    @mock_repo.add_file("clean.txt", "no secrets")

    # Mock the API client to avoid real network calls using stub
    mock_api_client = MockApiClient.new
    mock_api_client.github_response = {success: false, message: "Mocked - no real revocation"}

    # Test using direct token with proper GitHub PAT format
    Ace::Git::Secrets::Atoms::ServiceApiClient.stub :new, ->(**_opts) { mock_api_client } do
      output, = capture_io do
        Ace::Git::Secrets::Commands::RevokeCommand.execute(
          token: "ghp_test_example_token_for_revoke_1234567890AB"
        )
      end

      assert_match(/Token Revocation Results/i, output)
    end
  end

  def test_revoke_single_token_by_value
    @mock_repo.add_file("clean.txt", "no secrets")

    # Mock the API client using stub for thread-safety
    mock_api_client = MockApiClient.new
    mock_api_client.github_response = {success: true, message: "Token revoked"}

    Ace::Git::Secrets::Atoms::ServiceApiClient.stub :new, ->(**_opts) { mock_api_client } do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute(
          token: "ghp_test123456789012345678901234567890AB"
        )
        assert_equal 0, exit_code
      end

      assert_match(/\[OK\]/, output)
      assert_match(/github_pat_classic/i, output)
    end
  end

  def test_filters_by_service
    @mock_repo.add_file("clean.txt", "no secrets")

    # Mock the API client using stub for thread-safety
    mock_api_client = MockApiClient.new
    mock_api_client.github_response = {success: true, message: "Token revoked"}

    # Test using direct token with proper GitHub PAT format
    Ace::Git::Secrets::Atoms::ServiceApiClient.stub :new, ->(**_opts) { mock_api_client } do
      output, = capture_io do
        Ace::Git::Secrets::Commands::RevokeCommand.execute(
          token: "ghp_test_example_token_for_filter_1234567890AB",
          service: "github"
        )
      end

      # Output should show github service
      assert_match(/github/i, output)
    end
  end

  def test_handles_api_errors_gracefully
    @mock_repo.add_file("clean.txt", "no secrets")

    # Mock the API client to raise an error using stub for thread-safety
    mock_api_client = MockApiClient.new
    mock_api_client.should_raise = true

    Ace::Git::Secrets::Atoms::ServiceApiClient.stub :new, ->(**_opts) { mock_api_client } do
      capture_io do
        exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute(
          token: "ghp_test123456789012345678901234567890AB"
        )
        # Should return failure code
        assert [1, 2].include?(exit_code)
      end
    end
  end

  # Mock API client for testing
  class MockApiClient
    attr_accessor :github_response, :should_raise

    def initialize
      @github_response = {success: true, message: "Mocked"}
      @should_raise = false
    end

    def revoke_github_token(_token)
      raise "Simulated API error" if should_raise

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
          notes: "GitHub tokens can be revoked via API"
        }
      else
        {
          method: :manual,
          url: "https://example.com",
          notes: "Manual revocation required"
        }
      end
    end
  end
end
