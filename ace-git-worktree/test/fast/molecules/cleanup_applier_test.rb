# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/cleanup_applier"

class CleanupApplierTest < Minitest::Test
  def setup
    super
    @report = {
      plan_digest: "abcd123",
      repository: @temp_dir,
      actions: [
        {type: "remove_worktree", target: "#{@temp_dir}/feature", sha: "sha1"},
        {type: "delete_local_ref", target: "feature", sha: "sha2"},
        {type: "delete_remote_ref", target: "origin/feature", sha: "sha3"}
      ]
    }
    @applier = Ace::Git::Worktree::Molecules::CleanupApplier.new(@report, "abcd123")
  end

  def test_rejects_digest_mismatch
    applier = Ace::Git::Worktree::Molecules::CleanupApplier.new(@report, "wrong")
    result = applier.apply
    
    assert_equal false, result[:success]
    assert_includes result[:error], "Digest mismatch"
  end

  def test_stops_on_first_failure
    # Worktree removal fails due to dirty state
    @applier.stub(:safe_trash_path?, true) do
      @applier.stub(:dirty_state, {staged: ["file"]}) do
        result = @applier.apply
        
        assert_equal false, result[:success]
        assert_equal true, result[:partial_failure]
        
        ledger = result[:ledger]
        assert_equal 1, ledger.length
        assert_equal false, ledger[0][:success]
        assert_includes ledger[0][:error], "Worktree became dirty"
      end
    end
  end

  def test_successful_application
    @applier.stub(:safe_trash_path?, true) do
      @applier.stub(:dirty_state, {staged: [], unstaged: [], untracked: []}) do
        @applier.stub(:resolve_worktree_head, "sha1") do
          @applier.stub(:resolve_local_ref, "sha2") do
            
            # Mock Open3 calls
            mock_capture3 = lambda do |*cmd|
              if cmd[0..2] == ["git", "worktree", "remove"]
                return ["", "", Struct.new(:success?).new(true)]
              elsif cmd[0..2] == ["git", "branch", "-D"]
                return ["", "", Struct.new(:success?).new(true)]
              elsif cmd[0..3] == ["git", "push", "origin", "--delete"]
                return ["", "", Struct.new(:success?).new(true)]
              end
              ["", "", Struct.new(:success?).new(false)]
            end

            Open3.stub(:capture3, mock_capture3) do
              result = @applier.apply
              
              assert_equal true, result[:success]
              assert_equal false, result[:partial_failure]
              assert_equal 3, result[:ledger].length
              assert result[:ledger].all? { |l| l[:success] }
            end
          end
        end
      end
    end
  end
end
