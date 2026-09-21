# frozen_string_literal: true

require "test_helper"

module Forgejo
  class ParsersTest < AceGitForgejoTestCase
    VIEW_TEXT = <<~TEXT.freeze
      Ship the provider contract #25
      By lab-builder - Merged - +252 -8
      From `owner/repo:lab/W675-ace` into `main`
    TEXT

    def test_parse_pr_view_extracts_normalized_fields
      parsed = Ace::Git::Forgejo::Parsers.parse_pr_view(VIEW_TEXT)
      assert_equal 25, parsed[:number]
      assert_equal "Ship the provider contract", parsed[:title]
      assert_equal "lab-builder", parsed[:author]
      assert_equal :merged, parsed[:state]
      assert_equal "lab/W675-ace", parsed[:head_ref]
      assert_equal "main", parsed[:base_ref]
    end

    def test_parse_pr_view_handles_same_repo_head_without_owner_prefix
      text = "Fix parser edge case #8\nBy lab-builder - Open - +3 -1\nFrom `fix-parser` into `main`\n"
      parsed = Ace::Git::Forgejo::Parsers.parse_pr_view(text)
      assert_equal "fix-parser", parsed[:head_ref]
      assert_equal "main", parsed[:base_ref]
    end

    def test_parse_pr_view_returns_nil_for_unrecognized_output
      assert_nil Ace::Git::Forgejo::Parsers.parse_pr_view("unexpected\n")
    end

    def test_parse_head_sha_from_commits_output
      commits = "commit fc14c43d3660ac6c133959a6dec29603413f0e8a (+252, -8)\nAuthor: Lab Builder\n"
      assert_equal "fc14c43d3660ac6c133959a6dec29603413f0e8a", Ace::Git::Forgejo::Parsers.parse_head_sha(commits)
    end

    def test_parse_head_sha_returns_nil_without_commit_line
      assert_nil Ace::Git::Forgejo::Parsers.parse_head_sha("no commits\n")
    end

    def test_parse_search_extracts_entries
      listing = "2 pull requests\n#31: Wire status to providers (by lab-builder)\n#25: Ship the provider contract (by lab-admin)\n"
      entries = Ace::Git::Forgejo::Parsers.parse_search(listing)
      assert_equal 2, entries.length
      assert_equal({number: 31, title: "Wire status to providers", author: "lab-builder"}, entries[0])
      assert_equal({number: 25, title: "Ship the provider contract", author: "lab-admin"}, entries[1])
    end

    def test_parse_search_skips_summary_lines
      listing = "481 tasks\n#1: something (by someone)\n"
      entries = Ace::Git::Forgejo::Parsers.parse_search(listing)
      assert_equal 1, entries.length
    end

    def test_parse_issue_view_drops_pr_specific_fields
      text = "Broken diff on detached HEAD #9\nBy lab-admin - Open - +0 -0\n"
      parsed = Ace::Git::Forgejo::Parsers.parse_issue_view(text)
      assert_equal 9, parsed[:number]
      assert_equal "Broken diff on detached HEAD", parsed[:title]
      assert_equal :open, parsed[:state]
      refute parsed.key?(:head_ref)
    end

    def test_parse_actions_tasks_extracts_check_evidence
      tasks = "2 tasks\n#83 (fc14c43d3) failure Test Summary 0s (push): subject\n#82 (fc14c43d3660ac6c133959a6dec29603413f0e8a) success Complete package suite 1m29s (pull_request): subject\n"
      checks = Ace::Git::Forgejo::Parsers.parse_actions_tasks(tasks)
      assert_equal 2, checks.length
      assert_equal "Test Summary", checks[0][:name]
      assert_equal :failure, checks[0][:state]
      assert_equal "fc14c43d3", checks[0][:sha]
      assert_equal "Complete package suite", checks[1][:name]
      assert_equal :success, checks[1][:state]
    end

    def test_parse_repo_view_extracts_full_name_and_url
      view = "owner/repo\n> Sample repository\nView online at https://forge.example.com/owner/repo\n"
      parsed = Ace::Git::Forgejo::Parsers.parse_repo_view(view)
      assert_equal "owner/repo", parsed[:full_name]
      assert_equal "https://forge.example.com/owner/repo", parsed[:url]
    end

    # --- Real `fj` v0.6.0 output (captured live, isolate marks included) ---

    REAL_FIXTURES = File.expand_path("../../fixtures", __dir__).freeze

    def real_fixture(name)
      File.read(File.join(REAL_FIXTURES, name))
    end

    def test_clean_strips_bidi_isolate_and_pop_directional_marks
      assert_equal "abc def", Ace::Git::Forgejo::Parsers.clean("\u2068abc\u2069 def")
      assert_equal "clean", Ace::Git::Forgejo::Parsers.clean("\u202acl\u202cean\u2069")
    end

    def test_parse_pr_view_parses_real_fj_output
      parsed = Ace::Git::Forgejo::Parsers.parse_pr_view(real_fixture("pr_view_26.txt"))
      assert_equal 26, parsed[:number]
      assert_equal "Forge-neutral Git core with GitHub and Forgejo providers (8wk.t.l1e, F0)", parsed[:title]
      assert_equal "lab-builder", parsed[:author]
      assert_equal :open, parsed[:state]
      assert_equal "lab/W675-ace", parsed[:head_ref]
      assert_equal "main", parsed[:base_ref]
    end

    def test_parse_pr_view_real_evidence_contains_no_embedded_marks
      parsed = Ace::Git::Forgejo::Parsers.parse_pr_view(real_fixture("pr_view_26.txt"))
      [parsed[:title], parsed[:head_ref], parsed[:base_ref], parsed[:author]].each do |field|
        refute_includes field, "\u2068"
        refute_includes field, "\u2069"
      end
    end

    def test_parse_head_sha_from_real_commits_output
      assert_equal "1bc61f4c2f78d2b9e987f8898752029603be126b",
        Ace::Git::Forgejo::Parsers.parse_head_sha(real_fixture("pr_commits_26.txt"))
    end

    def test_parse_search_parses_real_fj_listing
      entries = Ace::Git::Forgejo::Parsers.parse_search(real_fixture("pr_search_all.txt"))
      assert_equal 26, entries.length
      assert_equal 26, entries[0][:number]
      assert_equal "Forge-neutral Git core with GitHub and Forgejo providers (8wk.t.l1e, F0)", entries[0][:title]
      assert_equal "lab-builder", entries[0][:author]
      assert_equal 1, entries.last[:number]
    end

    def test_parse_issue_view_parses_real_fj_output
      parsed = Ace::Git::Forgejo::Parsers.parse_issue_view(real_fixture("issue_view_26.txt"))
      assert_equal 26, parsed[:number]
      assert_equal "lab-builder", parsed[:author]
      assert_equal :open, parsed[:state]
      refute parsed.key?(:head_ref)
    end

    def test_parse_repo_view_real_url_evidence_is_clean
      parsed = Ace::Git::Forgejo::Parsers.parse_repo_view(real_fixture("repo_view.txt"))
      assert_equal "cs3b/ace", parsed[:full_name]
      assert_equal "https://forgejo.tail6c0887.ts.net/cs3b/ace", parsed[:url]
    end
  end
end
