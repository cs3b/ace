# frozen_string_literal: true

require "test_helper"

class GithubIssueTrackingProviderTest < AceGitGithubTestCase
  SERVER = Ace::Git::ResolvedServer.new(name: "github", provider: :github,
    url: "https://github.example.com/owner/repo")

  def test_tracking_read_binds_repository_and_paginates_comments
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1..2] == ["issue", "view"]
        {"number" => 42, "title" => "Issue", "state" => "OPEN",
         "author" => {"login" => "dev"}, "url" => "https://github.example.com/owner/repo/issues/42",
         "labels" => [{"name" => "customer"}]}.to_json
      else
        [[{"id" => 99, "body" => "<!-- ace-task:tracked -->"}]].to_json
      end
      {success: true, stdout: stdout, stderr: "", exit_code: 0}
    end
    snapshot = Ace::Git::Github::Provider.new(server: SERVER, runner: runner).issue_tracking(number: 42)
    assert_equal 99, snapshot[:comments].first[:id]
    assert_equal ["customer"], snapshot[:labels]
    assert calls.any? { |argv| argv.include?("--repo") && argv.include?("github.example.com/owner/repo") }
    assert calls.any? { |argv| argv.include?("--hostname") && argv.include?("github.example.com") }
  end

  def test_mutation_uses_selected_host_and_repository_path
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      {success: true, stdout: "{}", stderr: "", exit_code: 0}
    end
    provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    provider.create_issue_comment(number: 42, body: "@literal text")
    args = calls.first
    assert_includes args, "repos/owner/repo/issues/42/comments"
    assert_includes args, "github.example.com"
    assert_includes args, "--raw-field"
    assert_includes args, "body=@literal text"
  end

  def test_comment_mutation_refuses_id_not_on_selected_issue
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1] == "issue"
        {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
         "url" => "https://github.example.com/owner/repo/issues/42", "labels" => []}.to_json
      else
        "[[]]"
      end
      {success: true, stdout: stdout, stderr: "", exit_code: 0}
    end
    provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    assert_raises(Ace::Git::ProviderIdentityMismatchError) do
      provider.delete_issue_comment(number: 42, comment_id: 999)
    end
    refute calls.any? { |args| args.include?("DELETE") }
  end

  def test_issue_calls_preserve_configured_port
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1..2] == ["issue", "view"]
        {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
         "url" => "https://forge.example:8443/owner/repo/issues/42", "labels" => []}.to_json
      else
        "[[]]"
      end
      {success: true, stdout: stdout, stderr: "", exit_code: 0}
    end
    server = Ace::Git::ResolvedServer.new(name: "gh", provider: :github,
      url: "https://forge.example:8443/owner/repo")
    provider = Ace::Git::Github::Provider.new(server: server, runner: runner)
    provider.issue_tracking(number: 42)
    provider.create_issue_comment(number: 42, body: "x")
    assert calls.any? { |argv| argv.include?("--hostname") && argv.include?("forge.example:8443") }
    refute calls.any? { |argv| argv.include?("forge.example") && !argv.include?("forge.example:8443") }
  end

  def test_issue_calls_work_with_ssh_style_server_url
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1..2] == ["issue", "view"]
        {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
         "url" => "https://github.example.com/owner/repo/issues/42", "labels" => []}.to_json
      else
        "[[]]"
      end
      {success: true, status: 200, stdout: stdout, stderr: "", exit_code: 0}
    end
    server = Ace::Git::ResolvedServer.new(name: "gh", provider: :github,
      url: "git@github.example.com:owner/repo.git")
    provider = Ace::Git::Github::Provider.new(server: server, runner: runner)
    provider.issue_tracking(number: 42)
    provider.create_issue_comment(number: 42, body: "x")
    assert calls.any? { |argv| argv.any? { |arg| arg.to_s == "repos/owner/repo/issues/42/comments" } }
    assert calls.any? { |argv| argv.include?("github.example.com") }
  end

  def test_issue_evidence_rejects_number_mismatch_in_url
    runner = lambda do |args:, **_options|
      {success: true, status: 200,
       stdout: {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
                "url" => "https://github.example.com/owner/repo/issues/43", "labels" => []}.to_json}
    end
    provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.issue_tracking(number: 42) }
  end

  def test_issue_evidence_rejects_scheme_mismatch
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      {success: true, status: 200,
       stdout: {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
                "url" => "http://github.example.com/owner/repo/issues/42", "labels" => []}.to_json}
    end
    provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.issue_tracking(number: 42) }
  end

  def test_missing_or_unknown_issue_state_is_malformed
    runner = lambda do |args:, **_options|
      {success: true, status: 200,
       stdout: {"number" => 42, "title" => "Issue", "state" => "PLUMING", "author" => nil,
                "url" => "https://github.example.com/owner/repo/issues/42", "labels" => []}.to_json}
    end
    provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    assert_raises(Ace::Git::ProviderMalformedOutputError) { provider.issue_tracking(number: 42) }
  end

  def test_issue_calls_tolerate_trailing_slash_in_server_url
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1..2] == ["issue", "view"]
        {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
         "url" => "https://github.example.com/owner/repo/issues/42", "labels" => []}.to_json
      else
        "[[]]"
      end
      {success: true, stdout: stdout, stderr: "", exit_code: 0}
    end
    server = Ace::Git::ResolvedServer.new(name: "gh", provider: :github,
      url: "https://github.example.com/owner/repo/")
    provider = Ace::Git::Github::Provider.new(server: server, runner: runner)
    provider.issue_tracking(number: 42)
    assert calls.any? { |argv| argv.any? { |arg| arg.to_s.start_with?("repos/owner/repo/") && !arg.to_s.include?("//") } }
  end

  def test_issue_calls_strip_clone_suffix_with_trailing_slash
    calls = []
    runner = lambda do |args:, **_options|
      calls << args
      stdout = if args[1..2] == ["issue", "view"]
        {"number" => 42, "title" => "Issue", "state" => "OPEN", "author" => nil,
         "url" => "https://github.example.com/owner/repo/issues/42", "labels" => []}.to_json
      else
        "[[]]"
      end
      {success: true, stdout: stdout, stderr: "", exit_code: 0}
    end
    server = Ace::Git::ResolvedServer.new(name: "gh", provider: :github,
      url: "https://github.example.com/owner/repo.git/")
    provider = Ace::Git::Github::Provider.new(server: server, runner: runner)
    provider.issue_tracking(number: 42)
    assert calls.any? { |argv| argv.any? { |arg| arg.to_s == "repos/owner/repo/issues/42/comments" } }
    refute calls.any? { |argv| argv.any? { |arg| arg.to_s.include?(".git") } }
  end
end
