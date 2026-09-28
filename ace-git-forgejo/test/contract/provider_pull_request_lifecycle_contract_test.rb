# frozen_string_literal: true

require "test_helper"

# PR-lifecycle contract parity suite for the Forgejo provider.
# Shares identical assertions with ace-git-github via
# Ace::TestSupport::PullRequestLifecycleContract; fixtures are `fj`-shaped.
class ForgejoProviderPullRequestLifecycleContractTest < AceGitForgejoTestCase
  include Ace::TestSupport::PullRequestLifecycleContract

  CONTRACT = Ace::TestSupport::PullRequestLifecycleContract
  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :forgejo, url: CONTRACT::SERVER_URL)
  SHA = CONTRACT::HEAD_SHA

  def build_provider(runner)
    Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
  end

  def ready_supported?
    false
  end

  # `fj pr merge` cannot enforce an expected-head precondition atomically.
  def merge_supported?
    false
  end

  def lifecycle_runner(scenario)
    return create_new_stateful_runner if scenario == :create_new

    scripted_runner(scenario_responses.fetch(scenario))
  end

  # `create` runs the same search twice (pre-check plus reconciliation), so
  # this runner serves an empty listing first and the created PR afterwards.
  def create_new_stateful_runner
    searches = 0
    lambda do |args:, timeout: nil, env: nil|
      key = args.join(" ")
      case key
      when SEARCH_KEY
        searches += 1
        ok(search_listing(searches > 1 ? [25] : []))
      when "fj pr create Ship it --head feature/x --base main"
        ok("")
      when VIEW_25
        ok(pr_view_text(25, "Open", "feature/x", "main"))
      when COMMITS_25
        ok("commit #{SHA}\n")
      else
        flunk("Unexpected command in test: #{key}")
      end
    end
  end

  SEARCH_KEY = "fj --style minimal pr search --state open"
  VIEW_25 = "fj --style minimal pr view 25"
  VIEW_26 = "fj --style minimal pr view 26"
  COMMITS_25 = "fj --style minimal pr view 25 commits"
  COMMITS_26 = "fj --style minimal pr view 26 commits"

  def scenario_responses
    @scenario_responses ||= {
      find_single: {
        SEARCH_KEY => ok(search_listing([25])),
        VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
        COMMITS_25 => ok("commit #{SHA}\nAuthor: lab-builder\n Subject: ship\n")
      },
      find_multi: {
        SEARCH_KEY => ok(search_listing([25, 26])),
        VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
        VIEW_26 => ok(pr_view_text(26, "Open", "feature/x", "main")),
        COMMITS_25 => ok("commit #{SHA}\n"),
        COMMITS_26 => ok("commit #{CONTRACT::OTHER_SHA}\n")
      },
      create_new: {},
      create_existing: {
        SEARCH_KEY => ok(search_listing([25])),
        VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
        COMMITS_25 => ok("commit #{SHA}\n")
      },
      create_unknown: {
        SEARCH_KEY => ok(search_listing([])),
        "fj pr create Ship it --head feature/x --base main" => [
          "dial tcp: connect: connection refused", 1
        ]
      },
      update_stale: {
        VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
        COMMITS_25 => ok("commit #{SHA}\n")
      },
      update_ok: {
        VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
        COMMITS_25 => ok("commit #{SHA}\n"),
        "fj pr edit 25 title New title" => ok("")
      },
      ready_unsupported: {},
      merge_unsupported: {}
    }
  end

  def test_lifecycle_create_refuses_fork_head_before_any_mutation
    provider = build_provider(scripted_runner({}))
    error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
      provider.create_pull_request(
        head_repository_url: "#{CONTRACT::SERVER_URL.gsub("forge.example.com", "other.example.com")}/fork",
        head_ref: "feature/x", base_ref: "main", expected_head: SHA, title: "Ship it"
      )
    end
    assert_match(/cannot target head repository/i, error.message)
  end

  def test_lifecycle_update_splits_title_and_body_into_separate_commands
    runner = scripted_runner(
      VIEW_25 => ok(pr_view_text(25, "Open", "feature/x", "main")),
      COMMITS_25 => ok("commit #{SHA}\n"),
      "fj pr edit 25 title New title" => ok(""),
      "fj pr edit 25 body New body" => ok("")
    )
    receipt = build_provider(runner).update_pull_request(
      number: 25, expected_head: SHA, title: "New title", body: "New body"
    )
    assert_equal :update, receipt.operation
    assert_equal SHA, receipt.pull_request.head_sha
  end

  private

  def ok(stdout)
    {success: true, stdout: stdout, stderr: "", exit_code: 0}
  end

  def search_listing(numbers)
    return "0 pull requests\n" if numbers.empty?

    numbers.map { |n| "##{n}: Ship it (by lab-builder)" }.join("\n") + "\n"
  end

  def pr_view_text(number, state, head_ref, base_ref)
    <<~VIEW
      Ship it ##{number}
      By lab-builder - #{state} - +10 -2
      From `#{head_ref}` into `#{base_ref}`
    VIEW
  end

end
