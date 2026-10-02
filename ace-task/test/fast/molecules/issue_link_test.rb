# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/issue_link"
require "ostruct"

class IssueLinkTest < AceTaskTestCase
  def setup
    @server = Ace::Git::ResolvedServer.new(name: "lab", provider: :forgejo,
      url: "https://forge.example/owner/repo")
  end

  def test_number_resolves_selected_server
    Ace::Git::ServerRegistry.stub(:resolve_for, @server) do
      identity = Ace::Task::Molecules::IssueLink.from_input("42", server_name: "lab")
      assert_equal "lab", identity["server_name"]
      assert_equal :forgejo, @server.provider
      assert_equal 42, identity["number"]
    end
  end

  def test_number_resolves_configured_default_forgejo
    Ace::Git::ServerRegistry.stub(:resolve_for, @server) do
      identity = Ace::Task::Molecules::IssueLink.from_input("42", use_default: true)
      assert_equal "lab", identity["server_name"]
      assert_equal "forgejo", identity["provider"]
    end
  end

  def test_github_issue_url_selects_matching_configured_server
    github = Ace::Git::ResolvedServer.new(name: "github", provider: :github,
      url: "https://github.com/owner/repo")
    Ace::Git::ServerRegistry.stub(:matching_servers, [github]) do
      identity = Ace::Task::Molecules::IssueLink.from_input(
        "https://github.com/owner/repo/issues/17"
      )
      assert_equal "github", identity["server_name"]
      assert_equal 17, identity["number"]
    end
  end

  def test_url_and_server_mismatch_fails_before_provider
    Ace::Git::ServerRegistry.stub(:resolve_for, @server) do
      Ace::Git::ServerRegistry.stub(:matching_servers, []) do
        assert_raises(Ace::Git::AmbiguousRemoteError) do
          Ace::Task::Molecules::IssueLink.from_input(
            "https://other.example/owner/repo/issues/42", server_name: "lab"
          )
        end
      end
    end
  end

  def test_changed_server_identity_refuses_stored_link
    identity = {"server_name" => "lab", "provider" => "forgejo",
                "repository_url" => "https://forge.example/owner/repo", "number" => 42,
                "url" => "https://forge.example/owner/repo/issues/42"}
    changed = Ace::Git::ResolvedServer.new(name: "lab", provider: :github,
      url: "https://github.com/owner/repo")
    Ace::Git::ServerRegistry.stub(:resolve, changed) do
      Ace::Git::ServerRegistry.stub(:resolve_for, changed) do
        assert_raises(Ace::Git::ProviderIdentityMismatchError) do
          Ace::Task::Molecules::IssueLink.validate!(identity)
        end
      end
    end
  end

  def test_stored_identity_ignores_changed_default
    identity = {"server_name" => "lab", "provider" => "forgejo",
                "repository_url" => @server.url, "number" => 42,
                "url" => "#{@server.url}/issues/42"}
    Ace::Git::ServerRegistry.stub(:resolve, @server) do
      Ace::Git::ServerRegistry.stub(:resolve_for, @server) do
        Ace::Git::ServerRegistry.stub(:resolve_default, -> { flunk "changed default was consulted" }) do
          assert_equal @server, Ace::Task::Molecules::IssueLink.validate!(identity)
        end
      end
    end
  end

  def test_partial_mapping_fails
    assert_raises(ArgumentError) do
      Ace::Task::Molecules::IssueLink.validate!({"number" => 42})
    end
  end

  def test_web_url_derives_https_from_ssh_style_server
    Ace::Git::ServerRegistry.stub(:resolve_for, OpenStruct.new(name: "gh", provider: "github",
      url: "git@github.com:owner/repo.git")) do
      identity = Ace::Task::Molecules::IssueLink.from_input("42", server_name: "gh")
      assert_equal "https://github.com/owner/repo/issues/42", identity.fetch("url")
      assert_equal "git@github.com:owner/repo.git", identity.fetch("repository_url")
    end
  end

  def test_ambiguous_url_rejects_explicit_selection
    matches = [
      OpenStruct.new(name: "one", provider: "github", url: "https://github.example.com/owner/repo"),
      OpenStruct.new(name: "two", provider: "github", url: "https://git.example.com/owner/repo")
    ]
    Ace::Git::ServerRegistry.stub(:matching_servers, matches) do
      Ace::Git::ServerRegistry.stub(:resolve_for, matches.first) do
        error = assert_raises(Ace::Git::AmbiguousRemoteError) do
          Ace::Task::Molecules::IssueLink.from_input("https://github.example.com/owner/repo/issues/42",
            server_name: "one")
        end
        assert_match(/multiple configured servers/, error.message)
      end
    end
  end
end
