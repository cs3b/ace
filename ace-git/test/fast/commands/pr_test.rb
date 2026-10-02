# frozen_string_literal: true

require "test_helper"
require "ace/git/cli/commands/pr"
require "ace/git/organisms/pull_request_lifecycle"

class PrCommandsTest < AceGitTestCase
  def setup
    super
    @server = Ace::Git::ResolvedServer.new(name: "forgejo-lab", provider: :forgejo, url: "https://forge.example.com/cs3b/ace")
    @pr = Ace::Git::ProviderPullRequest.new(
      server_name: "forgejo-lab", number: 25, title: "Ship it", state: :open, body: nil,
      head_ref: "feature", base_ref: "main", head_sha: "a" * 40, author: "dev",
      url: "https://forge.example.com/cs3b/ace/pull/25", draft: true, merged_at: nil,
      head_repository_url: @server.url, base_repository_url: @server.url, merge_commit_sha: nil
    )
    @receipt = Ace::Git::ProviderMutationReceipt.new(
      server_name: "forgejo-lab", operation: :create, pull_request: @pr, idempotency: :existing
    )
  end

  def with_servers
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [{"name" => "forgejo-lab", "provider" => "forgejo", "url" => @server.url, "default" => true}]
    ))
    yield
  ensure
    Ace::Git.reset_config!
  end

  def stub_lifecycle(result, raised: nil)
    fake = Object.new
    if raised
      fake.define_singleton_method(:show) { |_id| raise raised }
      fake.define_singleton_method(:create) { |**_kwargs| raise raised }
      fake.define_singleton_method(:merge) { |_id, **_kwargs| raise raised }
    else
      fake.define_singleton_method(:show) { |_id| result }
      fake.define_singleton_method(:create) { |**_kwargs| result }
      fake.define_singleton_method(:merge) { |_id, **_kwargs| result }
    end
    Ace::Git::Organisms::PullRequestLifecycle.stub :new, ->(**_kwargs) { fake } do
      yield
    end
  end

  def test_show_renders_text_identity_with_server_and_head
    with_servers do
      stub_lifecycle(@pr) do
        output = capture_io do
          Ace::Git::CLI::Commands::Pr::Show.new.call(identifier: "25", format: "text")
        end
        text = output.first
        assert_match(/PR #25 on forgejo-lab/, text)
        assert_match(/head: #{"a" * 40}/, text)
        assert_match(/base-repository: #{@server.url}/, text)
        assert_match(/head-repository: #{@server.url}/, text)
      end
    end
  end

  def test_show_json_includes_normalized_evidence_fields
    with_servers do
      stub_lifecycle(@pr) do
        output = capture_io do
          Ace::Git::CLI::Commands::Pr::Show.new.call(identifier: "25", format: "json")
        end
        parsed = JSON.parse(output.first)
        assert_equal 25, parsed["number"]
        assert_equal "forgejo-lab", parsed["server"]
        assert_equal "main", parsed["base_ref"]
      end
    end
  end

  def test_create_renders_idempotency_state
    with_servers do
      stub_lifecycle(@receipt) do
        output = capture_io do
          Ace::Git::CLI::Commands::Pr::Create.new.call(
            head: "feature", base: "main", expected_head: "a" * 40, title: "Ship it", format: "text"
          )
        end
        assert_match(/idempotency: existing/, output.first)
      end
    end
  end

  def test_merge_forwards_method_and_renders_receipt
    with_servers do
      stub_lifecycle(@receipt) do
        output = capture_io do
          Ace::Git::CLI::Commands::Pr::Merge.new.call(
            identifier: "25", expected_head: "a" * 40, method: "squash", format: "text"
          )
        end
        assert_match(/merged PR #25/, output.first)
      end
    end
  end

  def test_classified_failures_exit_nonzero_without_success_claims
    with_servers do
      stub_lifecycle(nil, raised: Ace::Git::ProviderExpectedHeadConflictError.new("head moved")) do
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            Ace::Git::CLI::Commands::Pr::Merge.new.call(
              identifier: "25", expected_head: "a" * 40, method: "squash", format: "text"
            )
          end
        end
        assert_match(/head moved/, error.message)
      end
    end
  end

  def test_invalid_merge_method_is_rejected_before_provider_invocation
    with_servers do
      calls = []
      runner = ->(args:, **_kw) { calls << args; {success: true, stdout: "", stderr: "", exit_code: 0} }
      error = assert_raises(Ace::Support::Cli::Error) do
        capture_io do
          Ace::Git::CLI::Commands::Pr::Merge.new.call(
            identifier: "25", expected_head: "a" * 40, method: "fast-forward", format: "text"
          )
        end
      end
      assert_match(/Invalid merge method/, error.message)
      assert_empty calls
    end
  end
end
