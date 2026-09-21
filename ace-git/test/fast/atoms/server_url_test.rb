# frozen_string_literal: true

require "test_helper"

module Atoms
  class ServerUrlTest < AceGitTestCase
    def test_normalizes_https_url_and_strips_git_suffix
      assert_equal "forgejo.example.com/owner/repo",
        Ace::Git::Atoms::ServerUrl.normalize("https://forgejo.example.com/owner/repo.git")
    end

    def test_normalizes_scp_style_remote
      assert_equal "forgejo.example.com/owner/repo",
        Ace::Git::Atoms::ServerUrl.normalize("git@forgejo.example.com:owner/repo.git")
    end

    def test_normalizes_ssh_url_with_port_and_user
      assert_equal "forgejo.example.com:2222/owner/repo",
        Ace::Git::Atoms::ServerUrl.normalize("ssh://git@forgejo.example.com:2222/owner/repo.git")
    end

    def test_normalizes_bare_host_path_form
      assert_equal "forgejo.example.com/owner/repo",
        Ace::Git::Atoms::ServerUrl.normalize("forgejo.example.com/owner/repo/")
    end

    def test_matching_is_case_insensitive
      assert Ace::Git::Atoms::ServerUrl.match?(
        "https://Forgejo.Example.com/Owner/Repo",
        "git@forgejo.example.com:Owner/Repo.git"
      )
    end

    def test_match_returns_false_for_different_hosts
      refute Ace::Git::Atoms::ServerUrl.match?(
        "https://forgejo.example.com/owner/repo",
        "https://github.example.com/owner/repo"
      )
    end

    def test_match_returns_false_for_empty_input
      refute Ace::Git::Atoms::ServerUrl.match?("", "https://forgejo.example.com/owner/repo")
      refute Ace::Git::Atoms::ServerUrl.match?("https://forgejo.example.com/owner/repo", nil)
    end
  end
end
