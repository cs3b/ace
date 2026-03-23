# frozen_string_literal: true

require "test_helper"

class PrCreatorTest < Minitest::Test
  include TestHelper

  def setup
    @creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)
    # Reset cached values to ensure stubs work properly
    @creator.instance_variable_set(:@gh_available, nil)
    @creator.instance_variable_set(:@gh_authenticated, nil)
  end

  # --- Initialization Tests ---

  def test_initialization_with_default_timeout
    creator = Ace::Git::Worktree::Molecules::PrCreator.new
    assert_instance_of Ace::Git::Worktree::Molecules::PrCreator, creator
  end

  def test_initialization_with_custom_timeout
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 60)
    assert_instance_of Ace::Git::Worktree::Molecules::PrCreator, creator
  end

  # --- gh Availability Tests ---

  def test_gh_available_caches_result
    # Manually set the cached value
    @creator.instance_variable_set(:@gh_available, true)

    # Call twice to verify caching - should return cached value
    result1 = @creator.gh_available?
    result2 = @creator.gh_available?

    assert_equal true, result1
    assert_equal result1, result2
  end

  def test_gh_not_available_message
    message = @creator.gh_not_available_message

    assert_includes message, "gh CLI is required"
    assert_includes message, "brew install gh"
    assert_includes message, "gh auth login"
  end

  # --- Error Handling Tests ---

  def test_create_draft_returns_error_when_gh_not_available
    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    # Stub gh_available? to return false
    creator.stub :gh_available?, false do
      result = creator.create_draft(
        branch: "test-branch",
        base: "main",
        title: "Test PR"
      )

      assert_equal false, result[:success]
      assert_includes result[:error], "not installed"
    end
  end

  def test_create_draft_returns_error_when_not_authenticated
    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, true do
      creator.stub :gh_authenticated?, false do
        result = creator.create_draft(
          branch: "test-branch",
          base: "main",
          title: "Test PR"
        )

        assert_equal false, result[:success]
        assert_includes result[:error], "not authenticated"
      end
    end
  end

  def test_create_draft_returns_existing_pr_if_found
    existing_pr = {number: 123, url: "https://github.com/owner/repo/pull/123"}

    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, true do
      creator.stub :gh_authenticated?, true do
        creator.stub :find_existing_pr, existing_pr do
          result = creator.create_draft(
            branch: "test-branch",
            base: "main",
            title: "Test PR"
          )

          assert_equal true, result[:success]
          assert_equal 123, result[:pr_number]
          assert_equal "https://github.com/owner/repo/pull/123", result[:pr_url]
          assert_equal true, result[:existing]
        end
      end
    end
  end

  # --- PR Number Extraction Tests ---

  def test_extract_pr_number_from_url
    # Use private method via send
    pr_url = "https://github.com/owner/repo/pull/456"
    number = @creator.send(:extract_pr_number, pr_url)

    assert_equal 456, number
  end

  def test_extract_pr_number_handles_nil
    number = @creator.send(:extract_pr_number, nil)
    assert_nil number
  end

  def test_extract_pr_number_handles_invalid_url
    number = @creator.send(:extract_pr_number, "not-a-valid-url")
    assert_nil number
  end

  # --- Error Result Tests ---

  def test_error_result_structure
    result = @creator.send(:error_result, "Test error message")

    assert_equal false, result[:success]
    assert_nil result[:pr_number]
    assert_nil result[:pr_url]
    assert_equal "Test error message", result[:error]
  end

  # --- Handle Creation Error Tests ---

  def test_handle_creation_error_for_already_exists
    result = @creator.send(:handle_creation_error, "A pull request already exists for this branch")

    assert_equal false, result[:success]
    assert_includes result[:error], "already exists"
  end

  def test_handle_creation_error_for_authentication
    result = @creator.send(:handle_creation_error, "authentication required: not logged in")

    assert_equal false, result[:success]
    assert_includes result[:error], "not authenticated"
  end

  def test_handle_creation_error_for_network
    result = @creator.send(:handle_creation_error, "connection refused: network error")

    assert_equal false, result[:success]
    assert_includes result[:error], "Network error"
  end

  def test_handle_creation_error_for_repository_not_found
    result = @creator.send(:handle_creation_error, "repository not found")

    assert_equal false, result[:success]
    assert_includes result[:error], "repository"
  end

  def test_handle_creation_error_for_branch_not_found
    result = @creator.send(:handle_creation_error, "branch 'feature' not found on remote")

    assert_equal false, result[:success]
    assert_includes result[:error], "Push the branch first"
  end

  def test_handle_creation_error_for_generic_error
    result = @creator.send(:handle_creation_error, "Some unknown error occurred")

    assert_equal false, result[:success]
    assert_includes result[:error], "GitHub CLI error"
  end

  # --- Integration-style Tests (mocked) ---

  def test_create_draft_success_flow
    pr_url = "https://github.com/owner/repo/pull/789"

    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)
    # Reset cache to ensure stubs work
    creator.instance_variable_set(:@gh_available, nil)
    creator.instance_variable_set(:@gh_authenticated, nil)

    creator.stub :gh_available?, true do
      creator.stub :gh_authenticated?, true do
        creator.stub :find_existing_pr, nil do
          # Mock the execute_with_timeout to simulate success
          mock_execute = lambda { |_cmd, _timeout|
            mock_status = Minitest::Mock.new
            mock_status.expect(:success?, true)
            [pr_url, "", mock_status]
          }

          creator.stub :execute_with_timeout, mock_execute do
            result = creator.create_draft(
              branch: "feature-branch",
              base: "main",
              title: "Add feature"
            )

            assert_equal true, result[:success]
            assert_equal 789, result[:pr_number]
            assert_equal pr_url, result[:pr_url]
            assert_equal false, result[:existing]
          end
        end
      end
    end
  end

  def test_create_draft_with_body
    pr_url = "https://github.com/owner/repo/pull/999"
    captured_cmd = nil

    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, true do
      creator.stub :gh_authenticated?, true do
        creator.stub :find_existing_pr, nil do
          # Mock execute to capture the command
          mock_execute = lambda { |cmd, _timeout|
            captured_cmd = cmd
            [pr_url, "", Minitest::Mock.new.tap { |m| m.expect(:success?, true) }]
          }

          creator.stub :execute_with_timeout, mock_execute do
            creator.create_draft(
              branch: "feature-branch",
              base: "main",
              title: "Add feature",
              body: "This is the PR description"
            )

            # Verify body was included in command
            assert_includes captured_cmd, "--body"
            assert_includes captured_cmd, "This is the PR description"
          end
        end
      end
    end
  end

  def test_find_existing_pr_returns_nil_when_no_prs
    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, true do
      mock_execute = lambda { |_cmd, _timeout|
        ["[]", "", Minitest::Mock.new.tap { |m| m.expect(:success?, true) }]
      }

      creator.stub :execute_with_timeout, mock_execute do
        result = creator.find_existing_pr(branch: "non-existent-branch")
        assert_nil result
      end
    end
  end

  def test_find_existing_pr_returns_pr_data
    pr_json = '[{"number": 42, "url": "https://github.com/owner/repo/pull/42"}]'

    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)
    # Reset cache to ensure stubs work
    creator.instance_variable_set(:@gh_available, nil)

    creator.stub :gh_available?, true do
      mock_execute = lambda { |_cmd, _timeout|
        mock_status = Minitest::Mock.new
        mock_status.expect(:success?, true)
        [pr_json, "", mock_status]
      }

      creator.stub :execute_with_timeout, mock_execute do
        result = creator.find_existing_pr(branch: "existing-branch")

        refute_nil result, "Expected result to be a hash, got nil"
        assert_equal 42, result[:number]
        assert_equal "https://github.com/owner/repo/pull/42", result[:url]
      end
    end
  end

  def test_find_existing_pr_handles_json_parse_error
    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, true do
      mock_execute = lambda { |_cmd, _timeout|
        ["invalid json", "", Minitest::Mock.new.tap { |m| m.expect(:success?, true) }]
      }

      creator.stub :execute_with_timeout, mock_execute do
        result = creator.find_existing_pr(branch: "branch")
        assert_nil result
      end
    end
  end

  def test_find_existing_pr_returns_nil_when_gh_not_available
    # Create fresh instance to avoid cache issues
    creator = Ace::Git::Worktree::Molecules::PrCreator.new(timeout: 5)

    creator.stub :gh_available?, false do
      result = creator.find_existing_pr(branch: "any-branch")
      assert_nil result
    end
  end
end
