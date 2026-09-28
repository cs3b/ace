# frozen_string_literal: true

require "test_helper"

module Atoms
  class PrReferenceTest < AceGitTestCase
    def test_parses_bare_number_without_repository_identity
      parsed = Ace::Git::Atoms::PrReference.parse("25")
      assert_equal 25, parsed.number
      refute parsed.repository_explicit?
      assert_nil parsed.repository_url
      assert_nil parsed.owner_repo
    end

    def test_parses_owner_repo_number_form
      parsed = Ace::Git::Atoms::PrReference.parse("cs3b/ace#25")
      assert_equal 25, parsed.number
      assert_equal "cs3b/ace", parsed.owner_repo
      assert_nil parsed.repository_url
      assert parsed.repository_explicit?
    end

    def test_parses_github_style_url_with_pull_path
      parsed = Ace::Git::Atoms::PrReference.parse("https://forge.example.com/cs3b/ace/pull/25")
      assert_equal 25, parsed.number
      assert_equal "forge.example.com/cs3b/ace", parsed.repository_url
      assert_nil parsed.owner_repo
    end

    def test_parses_forgejo_style_url_with_pulls_path
      parsed = Ace::Git::Atoms::PrReference.parse("https://forge.example.com/cs3b/ace/pulls/25/files")
      assert_equal 25, parsed.number
      assert_equal "forge.example.com/cs3b/ace", parsed.repository_url
    end

    def test_url_normalization_strips_git_suffix_and_is_case_insensitive
      parsed = Ace::Git::Atoms::PrReference.parse("https://Forge.Example.com/cs3b/ace.git/pull/25")
      assert_equal "forge.example.com/cs3b/ace", parsed.repository_url
    end

    def test_rejects_unrecognized_shapes
      assert_nil Ace::Git::Atoms::PrReference.parse("")
      assert_nil Ace::Git::Atoms::PrReference.parse("abc")
      assert_nil Ace::Git::Atoms::PrReference.parse("25#")
      assert_nil Ace::Git::Atoms::PrReference.parse("owner/#25")
      assert_nil Ace::Git::Atoms::PrReference.parse("https://forge.example.com/cs3b/ace/tree/main")
      assert_nil Ace::Git::Atoms::PrReference.parse(nil)
    end
  end
end
