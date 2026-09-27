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
        end

        def metadata(head: @head, url: "https://github.com/example/repo/pull/7")
          {"headRefOid" => head, "baseRefOid" => @base, "url" => url}
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
