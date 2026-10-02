# frozen_string_literal: true

require "test_helper"
require "openssl"
require "ace/git/forgejo/issue_api"

class ForgejoIssueApiTest < AceGitForgejoTestCase
  SERVER = Ace::Git::ResolvedServer.new(name: "lab", provider: :forgejo,
    url: "https://forge.example.com/owner/repo")

  def test_token_lookup_uses_selected_authority
    Dir.mktmpdir do |dir|
      path = File.join(dir, "keys.json")
      File.write(path, JSON.generate("hosts" => {"forge.example.com" => {"token" => "secret"}}))
      RepositoryBindingStub.remove
      RepositoryBindingStub.install(path)
      api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5)
      assert_equal "secret", api.send(:access_token!)
    end
  end

  def test_reads_all_comment_pages_from_selected_repository
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      page = args[2].include?("page=1") ? Array.new(50) { |i| {"id" => i + 1, "body" => "text"} } :
        [{"id" => 51, "body" => "last"}]
      {success: true, status: 200, stdout: JSON.generate(page)}
    end
    api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5, runner: runner)
    assert_equal 51, api.comments(42).length
    assert calls.all? { |args| args[2].start_with?("https://forge.example.com/api/v1/repos/owner/repo/issues/42/comments?") }
  end

  def test_post_timeout_keeps_unknown_outcome
    runner = ->(**_args) { raise Net::ReadTimeout }
    api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5, runner: runner)
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { api.create_comment(42, "marker") }
  end

  def test_read_tls_failure_is_unreachable
    runner = ->(**_args) { raise OpenSSL::SSL::SSLError, "certificate verify failed" }
    api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5, runner: runner)
    assert_raises(Ace::Git::ProviderUnreachableError) { api.issue(42) }
  end

  def test_mutation_tls_failure_keeps_unknown_outcome
    runner = ->(**_args) { raise OpenSSL::SSL::SSLError, "handshake failed" }
    api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5, runner: runner)
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { api.create_comment(42, "marker") }
  end

  def test_auth_failure_is_classified_without_retry
    runner = ->(**_args) { {success: false, status: 401, stdout: ""} }
    api = Ace::Git::Forgejo::IssueApi.new(server: SERVER, timeout: 5, runner: runner)
    assert_raises(Ace::Git::ProviderAuthenticationError) { api.issue(42) }
  end

  def test_provider_tracking_rejects_wrong_repository_evidence
    runner = lambda do |args:, **_options|
      stdout = if args[2].include?("/issues/42?")
        "[]"
      else
        {"number" => 42, "title" => "Issue", "state" => "open",
         "html_url" => "https://forge.example.com/other/repo/issues/42"}.to_json
      end
      {success: true, status: 200, stdout: stdout}
    end
    provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.issue_tracking(number: 42) }
  end

  def test_provider_issue_mutations_use_exact_repository
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      if args[2].include?("/api/v1/orgs/")
        next {success: false, status: 404, stdout: ""}
      end
      stdout = args[2].include?("/labels?") ? [{"id" => 7, "name" => "ace:tracked"}].to_json : "{}"
      {success: true, status: 200, stdout: stdout}
    end
    provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
    provider.add_issue_label(number: 42, label: "ace:tracked")
    provider.set_issue_state(number: 42, state: :closed)
    assert calls.all? { |args| args[2].start_with?("https://forge.example.com/api/v1/") }
    assert calls.select { |args| %w[POST PATCH DELETE].include?(args[1]) }.all? do |args|
      args[2].start_with?("https://forge.example.com/api/v1/repos/owner/repo/")
    end
    assert calls.any? { |args| args[1] == "PATCH" && args[2].end_with?("/issues/42") }
  end
end
