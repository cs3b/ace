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

    def test_web_base_preserves_numeric_port_in_scheme_less_url
      assert_equal "https://forge.example:8443/owner/repo",
        Ace::Git::Atoms::ServerUrl.web_base("forge.example:8443/owner/repo")
    end

    def test_web_base_still_maps_scp_style_remote
      assert_equal "https://forge.example/owner/repo",
        Ace::Git::Atoms::ServerUrl.web_base("git@forge.example:owner/repo.git")
    end
  end
end
