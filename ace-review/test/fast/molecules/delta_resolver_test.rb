# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Molecules
      class DeltaResolverTest < AceReviewTest
        def setup
          super
          @repo = @test_dir
          git("init", "-q")
          git("config", "user.email", "test@example.com")
          git("config", "user.name", "Test")
          File.write(File.join(@repo, "a.txt"), "one\n")
          git("add", ".")
          git("commit", "-q", "-m", "base")
          @base = head_sha
          File.write(File.join(@repo, "a.txt"), "one\ntwo\n")
          git("add", ".")
          git("commit", "-q", "-m", "mid")
          @mid = head_sha
          File.write(File.join(@repo, "b.txt"), "new file\n")
          git("add", ".")
          git("commit", "-q", "-m", "head")
          @head = head_sha
          git("remote", "add", "origin", "git@github.com:example/repo.git")
          git("config", "branch.feature.remote", "origin")
          git("config", "branch.feature.merge", "refs/heads/feature")
        end

        def metadata(head: @head, url: "https://github.com/example/repo/pull/7")
          {"headRefOid" => head, "baseRefOid" => @base, "url" => url,
           "head_repository_url" => "https://github.com/example/repo"}
        end

        def test_explicit_reference_returns_intermediate_diff
          result = DeltaResolver.resolve(@mid, metadata, project_root: @repo)

          assert result[:success]
          assert_equal @mid, result[:reference_head]
          assert_equal :explicit, result[:source]
          assert_includes result[:diff], "b.txt"
        end

        def test_reference_equal_to_head_yields_empty_delta
          result = DeltaResolver.resolve(@head, metadata, project_root: @repo)

          assert result[:success]
          assert_equal "", result[:diff]
        end

        def test_stale_provider_head_cannot_certify_empty_delta_after_local_push
          git("branch", "feature", @head)
          write_session("review-prior", head: @mid, url: metadata["url"], mtime: Time.now)
          [:auto, @mid].each do |reference|
            result = DeltaResolver.resolve(reference, metadata(head: @mid).merge("headRefName" => "feature"), project_root: @repo)
            refute result[:success]
            assert_match(/local PR branch is newer/, result[:error])
            refute result.key?(:diff)
          end
          fresh = DeltaResolver.resolve(:auto, metadata.merge("headRefName" => "feature"), project_root: @repo)
          assert fresh[:success]
          assert_includes fresh[:diff], "b.txt"
        end

        def test_missing_branch_or_other_fork_cannot_infer_pr_freshness_from_local_head
          git("branch", "feature", @head)
          [metadata(head: @mid), metadata(head: @mid).merge("headRefName" => "feature",
            "head_repository_url" => "https://github.com/another-fork/repo")].each do |facts|
            result = DeltaResolver.resolve(@mid, facts, project_root: @repo)
            assert result[:success], result[:error]
            assert_equal "", result[:diff]
          end
        end

        def test_differently_named_push_destination_is_not_the_pr_source
          git("branch", "feature", @head)
          git("config", "remote.origin.push", "refs/heads/feature:refs/heads/another-feature")
          result = DeltaResolver.resolve(@mid, metadata(head: @mid).merge("headRefName" => "feature"), project_root: @repo)
          assert result[:success], result[:error]
          assert_equal "", result[:diff]
        end

        def test_upstream_push_to_another_branch_does_not_imply_stale_pr
          git("branch", "feature", @head)
          git("config", "push.default", "upstream")
          git("config", "branch.feature.merge", "refs/heads/another-feature")
          result = DeltaResolver.resolve(@mid, metadata(head: @mid).merge("headRefName" => "feature"), project_root: @repo)
          assert result[:success], result[:error]
          assert_equal "", result[:diff]
        end

        def test_simple_push_to_fork_uses_current_branch_despite_differently_named_upstream
          git("branch", "feature", @head)
          git("remote", "add", "upstream", "git@github.com:upstream/repo.git")
          git("config", "branch.feature.remote", "upstream")
          git("config", "branch.feature.merge", "refs/heads/main")
          git("config", "branch.feature.pushRemote", "origin")
          git("config", "push.default", "simple")
          result = DeltaResolver.resolve(@mid, metadata(head: @mid).merge("headRefName" => "feature"), project_root: @repo)
          refute result[:success]
          assert_match(/local PR branch is newer/, result[:error])
        end

        def test_unrelated_checkout_does_not_override_named_pr_branch
          git("branch", "feature", @mid)
          result = DeltaResolver.resolve(@mid, metadata(head: @mid).merge("headRefName" => "feature"), project_root: @repo)
          assert result[:success]
          assert_equal "", result[:diff]
        end

        def test_non_ancestor_reference_fails_closed
          git("checkout", "-q", "-b", "diverged", @mid)
          File.write(File.join(@repo, "c.txt"), "divergent\n")
          git("add", ".")
          git("commit", "-q", "-m", "diverged")
          diverged_head = head_sha
          git("checkout", "-q", "-")

          result = DeltaResolver.resolve(diverged_head, metadata, project_root: @repo)

          refute result[:success]
          assert_match(/not an ancestor/, result[:error])
        end

        def test_unknown_reference_is_refused
          result = DeltaResolver.resolve("deadbeef", metadata, project_root: @repo)

          refute result[:success]
          assert_match(/rev-parse|failed/, result[:error])
        end

        def test_auto_resolution_picks_most_recent_session_of_same_pr
          write_session("review-aaa", head: @mid, url: "https://github.com/example/repo/pull/7", mtime: Time.now - 60)
          write_session("review-bbb", head: @base, url: "https://github.com/example/repo/pull/7", mtime: Time.now)

          result = DeltaResolver.resolve(:auto, metadata, project_root: @repo)

          assert result[:success]
          assert_equal :session, result[:source]
          assert_equal @base, result[:reference_head]
          assert_includes result[:session_dir].to_s, "review-bbb"
        end

        def test_auto_resolution_ignores_other_prs_and_incomplete_sessions
          write_session("review-xxx", head: @mid, url: "https://github.com/example/other/pull/1", mtime: Time.now)

          result = DeltaResolver.resolve(:auto, metadata, project_root: @repo)

          refute result[:success]
          assert_match(/No prior review session/, result[:error])
        end

        def test_auto_resolution_without_any_session_refuses_full_review_fallback
          result = DeltaResolver.resolve(:auto, metadata, project_root: @repo)

          refute result[:success]
          assert_match(/No prior review session.*--delta <head>/m, result[:error])
        end

        private

        def head_sha
          out, _err = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo)
          out.strip
        end

        def git(*args)
          system("git", *args, chdir: @repo) or flunk "git #{args.join(" ")} failed"
        end

        def write_session(name, head:, url:, mtime:)
          dir = File.join(@repo, ".ace-local", "review", "sessions", name)
          FileUtils.mkdir_p(dir)
          metadata_path = File.join(dir, "metadata.yml")
          File.write(metadata_path, YAML.dump({
            "pr_url" => url,
            "diff_manifest" => {"head_sha" => head}
          }))
          File.utime(mtime, mtime, metadata_path)
        end
      end
    end
  end
end
