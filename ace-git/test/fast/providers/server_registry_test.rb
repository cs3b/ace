# frozen_string_literal: true

require "test_helper"

module Providers
  class ServerRegistryTest < AceGitTestCase
    def with_servers(servers, remote: "origin")
      Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => servers, "remote" => remote))
      yield
    ensure
      Ace::Git.reset_config!
    end

    def in_temp_repo
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          system("git", "init", "--quiet", "-b", "main", ".") || flunk("git init failed")
          system("git", "config", "user.email", "test@example.com") || flunk("git config failed")
          system("git", "config", "user.name", "Test") || flunk("git config failed")
          yield dir
        end
      end
    end

    def test_servers_empty_when_unconfigured
      Ace::Git.instance_variable_set(:@config, {})
      assert_equal [], Ace::Git::ServerRegistry.servers
    ensure
      Ace::Git.reset_config!
    end

    def test_servers_returns_resolved_identities_in_order
      with_servers([
        {"name" => "github-public", "provider" => "github", "url" => "https://git.example.com/owner/repo"},
        {"name" => "forgejo-lab", "provider" => :forgejo, "url" => "https://forgejo.example.com/owner/repo", "default" => true}
      ]) do
        servers = Ace::Git::ServerRegistry.servers
        assert_equal 2, servers.length
        assert_equal "github-public", servers[0].name
        assert_equal :github, servers[0].provider
        assert_equal "forgejo-lab", servers[1].name
        assert_equal :forgejo, servers[1].provider
      end
    end

    def test_resolve_returns_explicitly_named_server
      with_servers([
        {"name" => "github-public", "provider" => "github", "url" => "https://git.example.com/owner/repo"},
        {"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"}
      ]) do
        resolved = Ace::Git::ServerRegistry.resolve("forgejo-lab")
        assert_equal "forgejo-lab", resolved.name
        assert_equal :forgejo, resolved.provider
        assert_equal "https://forgejo.example.com/owner/repo", resolved.url
      end
    end

    def test_resolve_accepts_symbols
      with_servers([{"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com"}]) do
        assert_equal "forgejo-lab", Ace::Git::ServerRegistry.resolve(:'forgejo-lab').name
      end
    end

    def test_resolve_unknown_name_raises
      with_servers([{"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com"}]) do
        error = assert_raises(Ace::Git::UnknownServerNameError) do
          Ace::Git::ServerRegistry.resolve("nope")
        end
        assert_match(/nope/, error.message)
      end
    end

    def test_resolve_default_with_zero_defaults_raises
      with_servers([
        {"name" => "a", "provider" => "forgejo", "url" => "https://a.example.com"},
        {"name" => "b", "provider" => "github", "url" => "https://b.example.com"}
      ]) do
        error = assert_raises(Ace::Git::NoDefaultServerConfiguredError) do
          Ace::Git::ServerRegistry.resolve_default
        end
        assert_match(/default/, error.message)
      end
    end

    def test_resolve_default_with_exactly_one_default_succeeds
      with_servers([
        {"name" => "a", "provider" => "forgejo", "url" => "https://a.example.com"},
        {"name" => "b", "provider" => "github", "url" => "https://b.example.com", "default" => true}
      ]) do
        resolved = Ace::Git::ServerRegistry.resolve_default
        assert_equal "b", resolved.name
      end
    end

    def test_resolve_default_with_two_defaults_raises
      with_servers([
        {"name" => "a", "provider" => "forgejo", "url" => "https://a.example.com", "default" => true},
        {"name" => "b", "provider" => "github", "url" => "https://b.example.com", "default" => true}
      ]) do
        error = assert_raises(Ace::Git::MultipleDefaultServersError) do
          Ace::Git::ServerRegistry.resolve_default
        end
        assert_match(/a, b/, error.message)
      end
    end

    def test_duplicate_names_raise
      error = assert_raises(Ace::Git::DuplicateServerNameError) do
        with_servers([
          {"name" => "dupe", "provider" => "forgejo", "url" => "https://a.example.com"},
          {"name" => "dupe", "provider" => "github", "url" => "https://b.example.com"}
        ]) do
          Ace::Git::ServerRegistry.servers
        end
      end
      assert_match(/dupe/, error.message)
    end

    def test_malformed_entry_raises_config_error
      error = assert_raises(Ace::Git::ConfigError) do
        with_servers([{"name" => "broken", "provider" => "forgejo"}]) do
          Ace::Git::ServerRegistry.servers
        end
      end
      assert_match(/url/, error.message)
    end

    def test_non_mapping_entry_raises_config_error
      assert_raises(Ace::Git::ConfigError) do
        with_servers(["not-a-mapping"]) do
          Ace::Git::ServerRegistry.servers
        end
      end
    end

    def test_resolve_remote_matches_scp_style_remote_to_configured_server
      in_temp_repo do
        system("git", "remote", "add", "origin", "git@forgejo.example.com:owner/repo.git")
        with_servers([{"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"}]) do
          resolved = Ace::Git::ServerRegistry.resolve_remote("origin")
          assert_equal "forgejo-lab", resolved.name
        end
      end
    end

    def test_resolve_remote_defaults_to_configured_remote_name
      in_temp_repo do
        system("git", "remote", "add", "upstream", "https://forgejo.example.com/owner/repo.git")
        with_servers([{"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"}], remote: "upstream") do
          resolved = Ace::Git::ServerRegistry.resolve_remote
          assert_equal "forgejo-lab", resolved.name
        end
      end
    end

    def test_resolve_remote_with_no_matching_server_raises_ambiguous
      in_temp_repo do
        system("git", "remote", "add", "origin", "https://unknown.example.com/owner/repo.git")
        with_servers([{"name" => "forgejo-lab", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"}]) do
          error = assert_raises(Ace::Git::AmbiguousRemoteError) do
            Ace::Git::ServerRegistry.resolve_remote("origin")
          end
          assert_match(/matches no configured server/, error.message)
        end
      end
    end

    def test_resolve_remote_with_multiple_matches_raises_ambiguous
      in_temp_repo do
        system("git", "remote", "add", "origin", "https://forgejo.example.com/owner/repo.git")
        with_servers([
          {"name" => "forgejo-a", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"},
          {"name" => "forgejo-b", "provider" => "forgejo", "url" => "https://forgejo.example.com/owner/repo"}
        ]) do
          error = assert_raises(Ace::Git::AmbiguousRemoteError) do
            Ace::Git::ServerRegistry.resolve_remote("origin")
          end
          assert_match(/matches multiple configured servers/, error.message)
        end
      end
    end
  end
end
