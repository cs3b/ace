# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "open3"

module Ace
  module Lab
    module Molecules
      class OrdinaryMergeReadTest < Minitest::Test
        def setup
          @dir = File.realpath(Dir.mktmpdir("merge-read"))
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
          @merge = OrdinaryMergeRead.new(repo_path: @repo, base_ref: "refs/heads/main")
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

        def test_observations_never_expose_a_local_ref_mutation
          assert @merge.fast_forwardable?(@candidate)
          refute_respond_to @merge, :merge!
          assert_equal @base, git("rev-parse", "refs/heads/main")
        end

        def test_absolute_paths_and_full_refs_are_required
          assert_raises(ArgumentError) { OrdinaryMergeRead.new(repo_path: "relative", base_ref: "refs/heads/main") }
          assert_raises(ArgumentError) { OrdinaryMergeRead.new(repo_path: @repo, base_ref: "main") }
        end

        def test_exact_project_storage_is_used_despite_ambient_git_environment
          before = ENV["GIT_DIR"]
          ENV["GIT_DIR"] = "/nonexistent/foreign.git"
          assert_equal @base, @merge.base_head
          assert @merge.candidate_commit?(@candidate)
          assert @merge.fast_forwardable?(@candidate)
        ensure
          ENV["GIT_DIR"] = before
        end

        def test_linked_checkout_uses_the_installed_common_directory
          linked = File.join(@dir, "linked")
          git("worktree", "add", "--detach", linked, @candidate)
          reader = OrdinaryMergeRead.new(repo_path: linked, base_ref: "refs/heads/main",
            common_dir: File.join(@repo, ".git"))
          assert_equal @base, reader.base_head
          assert reader.fast_forwardable?(@candidate)
          wrong = OrdinaryMergeRead.new(repo_path: linked, base_ref: "refs/heads/main", common_dir: "/foreign/.git")
          assert_raises(OrdinaryMergeRead::GitUnavailable) { wrong.base_head }
        end

        def test_unavailable_storage_and_expired_deadline_are_not_negative_ancestry_proof
          expired = OrdinaryMergeRead.new(repo_path: @repo, base_ref: "refs/heads/main",
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1)
          assert_raises(OrdinaryMergeRead::GitUnavailable) { expired.candidate_commit?(@candidate) }
          File.open(File.join(@repo, ".git/config"), "a") { |file| file.write("\n[include]\npath=/foreign/config\n") }
          assert_raises(OrdinaryMergeRead::GitUnavailable) { @merge.base_head }
          assert_raises(OrdinaryMergeRead::GitUnavailable) { @merge.fast_forwardable?(@candidate) }
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
