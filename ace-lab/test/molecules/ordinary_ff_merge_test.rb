# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "open3"

module Ace
  module Lab
    module Molecules
      class OrdinaryFfMergeTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir("ff-merge")
          @repo = File.join(@dir, "repo")
          FileUtils.mkdir_p(@repo)
          git("init", "-b", "main")
          git("config", "user.name", "test")
          git("config", "user.email", "test@example.com")
          commit("base", "main.txt")
          @base = git("rev-parse", "HEAD")
          git("checkout", "-b", "feature")
          commit("candidate", "feature.txt")
          @candidate = git("rev-parse", "HEAD")
          git("checkout", "main")
          git("checkout", "-b", "sibling", "main")
          commit("divergent", "sibling.txt")
          @divergent = git("rev-parse", "HEAD")
          git("checkout", "main")
          @merge = OrdinaryFfMerge.new(repo_path: @repo, base_ref: "refs/heads/main")
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def test_base_head_reads_the_base_ref
          assert_equal @base, @merge.base_head
        end

        def test_candidate_existence_and_ff_precondition
          assert @merge.candidate_commit?(@candidate)
          refute @merge.candidate_commit?("f" * 40)
          # While main sits at the fork point, the candidate is a descendant.
          assert @merge.fast_forwardable?(@candidate)
          # Advance main past the fork point: the divergent sibling is no
          # longer a descendant — the non-fast-forwardable case.
          git("checkout", "main")
          File.write(File.join(@repo, "advance.txt"), "advance\n")
          git("add", "advance.txt")
          git("commit", "-m", "advance")
          refute @merge.fast_forwardable?(@divergent)
          refute @merge.fast_forwardable?(@candidate)
          git("update-ref", "refs/heads/main", "#{@base}")
          assert_equal @base, @merge.base_head
        end

        def test_ff_merge_moves_the_base_ref_to_the_candidate
          result = @merge.merge!(@candidate, @base)
          assert_equal :merged, result.outcome
          assert_equal @candidate, result.resulting_head
          assert_equal @base, result.previous_head
          assert_equal @candidate, git("rev-parse", "refs/heads/main")
          # ff proof: the resulting head IS the candidate — no merge commit.
        end

        def test_already_merged_is_a_no_op_success
          @merge.merge!(@candidate, @base)
          result = @merge.merge!(@candidate, @base)
          assert_equal :already_merged, result.outcome
          assert_equal @candidate, result.resulting_head
        end

        def test_race_lost_proves_no_effect
          result = @merge.merge!(@candidate, "9" * 40)
          assert_equal :race_lost, result.outcome
          assert_equal @base, git("rev-parse", "refs/heads/main")
        end

        def test_atomic_swap_loses_exactly_one_race
          # Two concurrent invocations with the same expected head: exactly
          # one ref CAS wins; the loser proves no effect.
          results = Array.new(2) { @merge.merge!(@candidate, @base) }
          winners = results.count { |r| r.outcome == :merged }
          assert_equal 1, winners
          assert_equal @candidate, git("rev-parse", "refs/heads/main")
        end

        def test_molecule_is_a_plain_cas_the_receiver_gates_the_ff_precondition
          # The molecule executes the ref CAS only; the fast-forward
          # PRECONDITION is enforced by the receiver (fast_forwardable? →
          # moved-target refusal family) so no silent strategy choice exists
          # at the transport level.
          result = @merge.merge!(@divergent, @base)
          assert_equal :merged, result.outcome
          git("update-ref", "refs/heads/main", @base)
          assert_equal @base, git("rev-parse", "refs/heads/main")
        end

        def test_absolute_paths_and_full_refs_are_required
          assert_raises(ArgumentError) { OrdinaryFfMerge.new(repo_path: "relative", base_ref: "refs/heads/main") }
          assert_raises(ArgumentError) { OrdinaryFfMerge.new(repo_path: @repo, base_ref: "main") }
        end

        private

        def commit(message, file)
          File.write(File.join(@repo, file), "#{message}\n")
          git("add", file)
          git("commit", "-m", message)
        end

        def git(*argv)
          out, stderr, status = Open3.capture3("git", *argv, chdir: @repo)
          raise "git #{argv.first} failed: #{stderr}" unless status.success?
          out.strip
        end
      end
    end
  end
end
