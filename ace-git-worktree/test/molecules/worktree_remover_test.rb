# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"
require "tmpdir"

class WorktreeRemoverTest < Minitest::Test
  def setup
    setup_temp_dir
    @remover = Ace::Git::Worktree::Molecules::WorktreeRemover.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_remove_without_delete_branch_keeps_branch
    # Create a test worktree
    worktree_path = File.join(@temp_dir, ".ace-wt", "test-branch")
    branch_name = "test-branch"

    # Mock: worktree exists
    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      # Mock: no uncommitted changes
      @remover.stub(:has_uncommitted_changes?, false) do
        # Mock: git worktree remove succeeds
        git_result = {success: true, output: "", error: nil}
        Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
          result = @remover.remove(worktree_path, delete_branch: false)

          assert result[:success]
          assert_equal worktree_path, result[:path]
          assert_equal branch_name, result[:branch]
          assert_equal false, result[:branch_deleted]
        end
      end
    end
  end

  def test_remove_with_delete_branch_on_merged_branch
    worktree_path = File.join(@temp_dir, ".ace-wt", "merged-branch")
    branch_name = "merged-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      @remover.stub(:has_uncommitted_changes?, false) do
        # Mock: git worktree remove succeeds
        git_remove_result = {success: true, output: "", error: nil}
        Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_remove_result) do
          # Mock: branch is merged (found in --merged output)
          merged_result = {success: true, output: "  #{branch_name}\n  main\n", error: nil}
          # Mock: branch deletion succeeds
          delete_result = {success: true, output: "", error: nil}

          Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, lambda { |*args|
            if args.include?("--merged")
              merged_result
            else
              delete_result
            end
          }) do
            result = @remover.remove(worktree_path, delete_branch: true)

            assert result[:success]
            assert_equal true, result[:branch_deleted]
          end
        end
      end
    end
  end

  def test_remove_with_delete_branch_on_unmerged_branch_without_force
    worktree_path = File.join(@temp_dir, ".ace-wt", "unmerged-branch")
    branch_name = "unmerged-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      @remover.stub(:has_uncommitted_changes?, false) do
        # Mock: git worktree remove succeeds
        git_remove_result = {success: true, output: "", error: nil}
        Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_remove_result) do
          # Mock: branch is NOT in --merged output
          merged_result = {success: true, output: "  main\n", error: nil}

          # Capture stderr output
          original_stderr = $stderr
          $stderr = StringIO.new
          begin
            Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, merged_result) do
              result = @remover.remove(worktree_path, delete_branch: true, force: false)

              # Worktree should be removed but branch should be kept
              assert result[:success]
              assert_equal false, result[:branch_deleted]

              # Check that warning was issued
              stderr_output = $stderr.string
              assert stderr_output.include?("not merged"), "Should have warned about unmerged branch"
            end
          ensure
            $stderr = original_stderr
          end
        end
      end
    end
  end

  def test_remove_with_delete_branch_and_force_on_unmerged_branch
    worktree_path = File.join(@temp_dir, ".ace-wt", "unmerged-branch")
    branch_name = "unmerged-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      @remover.stub(:has_uncommitted_changes?, false) do
        # Mock: git worktree remove succeeds
        git_remove_result = {success: true, output: "", error: nil}
        Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_remove_result) do
          # Mock: branch deletion with -D succeeds
          delete_result = {success: true, output: "Deleted branch #{branch_name}\n", error: nil}

          Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, delete_result) do
            result = @remover.remove(worktree_path, delete_branch: true, force: true)

            assert result[:success]
            assert_equal true, result[:branch_deleted]
          end
        end
      end
    end
  end

  def test_remove_with_uncommitted_changes_without_force
    worktree_path = File.join(@temp_dir, ".ace-wt", "dirty-branch")
    branch_name = "dirty-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      # Mock: worktree has uncommitted changes
      @remover.stub(:has_uncommitted_changes?, true) do
        result = @remover.remove(worktree_path, force: false)

        refute result[:success]
        assert_match(/uncommitted changes/, result[:error])
      end
    end
  end

  def test_remove_still_blocks_changes_when_ignore_untracked_enabled
    worktree_path = File.join(@temp_dir, ".ace-wt", "dirty-branch")
    branch_name = "dirty-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_info, worktree_info) do
      @remover.stub(:has_uncommitted_changes?, true) do
        result = @remover.remove(worktree_path, force: false, ignore_untracked: true)

        refute result[:success]
        assert_match(/uncommitted changes/, result[:error])
      end
    end
  end

  def test_remove_forwards_ignore_untracked_to_change_check
    worktree_path = File.join(@temp_dir, ".ace-wt", "clean-branch")
    branch_name = "clean-branch"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    received_ignore_untracked = nil

    @remover.stub(:find_worktree_info, worktree_info) do
      @remover.stub(:has_uncommitted_changes?, lambda { |_path, ignore_untracked: false|
        received_ignore_untracked = ignore_untracked
        false
      }) do
        git_result = {success: true, output: "", error: nil}
        Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
          result = @remover.remove(worktree_path, ignore_untracked: true)

          assert result[:success]
          assert_equal true, received_ignore_untracked
        end
      end
    end
  end

  def test_has_uncommitted_changes_ignores_untracked_files_when_requested
    Dir.mktmpdir("worktree-remover") do |worktree_path|
      Dir.chdir(worktree_path) do
        system("git", "init", "--quiet")
        File.write("tool-generated.tmp", "generated by test\n")
      end

      assert_equal true, @remover.send(:has_uncommitted_changes?, worktree_path)
      assert_equal false, @remover.send(:has_uncommitted_changes?, worktree_path, ignore_untracked: true)
    end
  end

  def test_remove_nonexistent_worktree
    worktree_path = File.join(@temp_dir, ".ace-wt", "nonexistent")

    # Mock: worktree not found
    @remover.stub(:find_worktree_info, nil) do
      result = @remover.remove(worktree_path)

      refute result[:success]
      assert_match(/not found/, result[:error])
    end
  end

  def test_delete_branch_if_safe_with_merged_branch
    branch_name = "merged-feature"

    # Mock: branch is in --merged output
    merged_result = {success: true, output: "  #{branch_name}\n  main\n", error: nil}
    delete_result = {success: true, output: "Deleted branch #{branch_name}\n", error: nil}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, lambda { |*args|
      if args.include?("--merged")
        merged_result
      else
        delete_result
      end
    }) do
      result = @remover.send(:delete_branch_if_safe, branch_name, false)

      assert result[:success]
      assert_match(/deleted/, result[:message])
    end
  end

  def test_delete_branch_if_safe_with_unmerged_branch
    branch_name = "unmerged-feature"

    # Mock: branch is NOT in --merged output
    merged_result = {success: true, output: "  main\n", error: nil}

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new
    begin
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, merged_result) do
        result = @remover.send(:delete_branch_if_safe, branch_name, false)

        refute result[:success]
        stderr_output = $stderr.string
        assert stderr_output.include?("not merged"), "Should have warned about unmerged branch"
      end
    ensure
      $stderr = original_stderr
    end
  end

  def test_delete_branch_if_safe_with_force
    branch_name = "feature-to-force-delete"

    # Mock: successful force delete
    delete_result = {success: true, output: "Deleted branch #{branch_name}\n", error: nil}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, delete_result) do
      result = @remover.send(:delete_branch_if_safe, branch_name, true)

      assert result[:success]
      assert_match(/deleted/, result[:message])
    end
  end

  def test_remove_by_branch
    branch_name = "feature-branch"
    worktree_path = File.join(@temp_dir, ".ace-wt", branch_name)

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_by_branch, worktree_info) do
      @remover.stub(:find_worktree_info, worktree_info) do
        @remover.stub(:has_uncommitted_changes?, false) do
          git_result = {success: true, output: "", error: nil}
          Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
            result = @remover.remove_by_branch(branch_name)

            assert result[:success]
            assert_equal branch_name, result[:branch]
          end
        end
      end
    end
  end

  def test_remove_by_task_id
    task_id = "081"
    worktree_path = File.join(@temp_dir, ".ace-wt", "task.#{task_id}")
    branch_name = "081-feature"

    worktree_info = mock_worktree_info(worktree_path, branch_name)
    @remover.stub(:find_worktree_by_task_id, worktree_info) do
      @remover.stub(:find_worktree_info, worktree_info) do
        @remover.stub(:has_uncommitted_changes?, false) do
          git_result = {success: true, output: "", error: nil}
          Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
            result = @remover.remove_by_task_id(task_id)

            assert result[:success]
          end
        end
      end
    end
  end

  private

  def mock_worktree_info(path, branch)
    worktree_info = Object.new
    worktree_info.define_singleton_method(:path) { path }
    worktree_info.define_singleton_method(:branch) { branch }
    worktree_info
  end
end
