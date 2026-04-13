# frozen_string_literal: true

require "test_helper"

class RepositoryStateDetectorTest < AceGitTestCase
  def setup
    super
    @detector = Ace::Git::Atoms::RepositoryStateDetector
    @executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_detect_returns_clean
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.detect
          assert_equal :clean, result, "Should return :clean when no changes"
        end
      end
    end
  end

  def test_detect_returns_dirty
    mock_result = {success: true, output: "M file.rb\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.detect
          assert_equal :dirty, result, "Should return :dirty when there are changes"
        end
      end
    end
  end

  def test_detect_returns_rebasing
    call_count = 0
    mock_proc = ->(*args) {
      call_count += 1
      if call_count == 1
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        # Stub File.exist? to return true for rebase-merge path
        File.stub :exist?, ->(path) { path.include?("rebase-merge") } do
          result = @detector.detect
          assert_equal :rebasing, result, "Should return :rebasing when rebase-merge exists"
        end
      end
    end
  end

  def test_detect_returns_merging
    call_count = 0
    mock_proc = ->(*args) {
      call_count += 1
      if call_count == 1
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        # Stub File.exist? to return true for MERGE_HEAD path
        File.stub :exist?, ->(path) { path.include?("MERGE_HEAD") } do
          result = @detector.detect
          assert_equal :merging, result, "Should return :merging when MERGE_HEAD exists"
        end
      end
    end
  end

  def test_detect_returns_unknown_when_not_in_git
    @executor.stub :in_git_repo?, false do
      result = @detector.detect
      assert_equal :unknown, result, "Should return :unknown when not in git repo"
    end
  end

  def test_clean_check_returns_true
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.clean?
          assert result, "Should return true when clean"
        end
      end
    end
  end

  def test_clean_check_returns_false
    mock_result = {success: true, output: "M file.rb\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.clean?
          refute result, "Should return false when dirty"
        end
      end
    end
  end

  def test_dirty_check_returns_true
    mock_result = {success: true, output: "M file.rb\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @detector.dirty?
        assert result, "Should return true when there are changes"
      end
    end
  end

  def test_dirty_check_returns_false
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @detector.dirty?
        refute result, "Should return false when clean"
      end
    end
  end

  def test_rebasing_check_returns_true
    mock_result = {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, ->(path) { path.include?("rebase-merge") } do
          result = @detector.rebasing?
          assert result, "Should return true when rebase-merge exists"
        end
      end
    end
  end

  def test_rebasing_check_returns_false
    mock_result = {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.rebasing?
          refute result, "Should return false when no rebase directory exists"
        end
      end
    end
  end

  def test_merging_check_returns_true
    mock_result = {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, ->(path) { path.include?("MERGE_HEAD") } do
          result = @detector.merging?
          assert result, "Should return true when MERGE_HEAD exists"
        end
      end
    end
  end

  def test_merging_check_returns_false
    mock_result = {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.merging?
          refute result, "Should return false when MERGE_HEAD doesn't exist"
        end
      end
    end
  end

  def test_state_description_returns_string_for_clean
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.state_description
          assert_equal "clean (no uncommitted changes)", result
        end
      end
    end
  end

  def test_state_description_returns_string_for_dirty
    mock_result = {success: true, output: "M file.rb\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        File.stub :exist?, false do
          result = @detector.state_description
          assert_equal "dirty (uncommitted changes)", result
        end
      end
    end
  end

  def test_state_description_returns_string_for_rebasing
    call_count = 0
    mock_proc = ->(*args) {
      call_count += 1
      if call_count == 1
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        File.stub :exist?, ->(path) { path.include?("rebase-merge") } do
          result = @detector.state_description
          assert_equal "rebasing in progress", result
        end
      end
    end
  end

  def test_state_description_returns_string_for_merging
    call_count = 0
    mock_proc = ->(*args) {
      call_count += 1
      if call_count == 1
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        File.stub :exist?, ->(path) { path.include?("MERGE_HEAD") } do
          result = @detector.state_description
          assert_equal "merge in progress", result
        end
      end
    end
  end

  def test_state_description_returns_string_for_unknown
    @executor.stub :in_git_repo?, false do
      result = @detector.state_description
      assert_equal "unknown state", result
    end
  end
end
