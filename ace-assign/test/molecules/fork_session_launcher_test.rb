# frozen_string_literal: true

require_relative "../test_helper"

class ForkSessionLauncherTest < AceAssignTestCase
  class FakeQueryInterface
    attr_reader :calls

    def initialize
      @calls = []
    end

    def query(provider_model, prompt = nil, **options)
      @calls << {
        provider_model: provider_model,
        prompt: prompt,
        options: options,
        env_assign_id: ENV["ACE_ASSIGN_ID"],
        env_fork_root: ENV["ACE_ASSIGN_FORK_ROOT"]
      }
      { text: "ok", provider: provider_model.split(":").first, model: provider_model.split(":")[1] }
    end
  end

  def test_launch_uses_config_defaults_and_sets_env_scope
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "codex:gpt-5", "timeout" => 900 },
      "providers" => { "cli_args" => { "codex" => "full-auto" } }
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010.01")

    call = fake.calls.last
    assert_equal "codex:gpt-5", call[:provider_model]
    assert_equal "/ace-assign-drive", call[:prompt]
    assert_equal "full-auto", call[:options][:cli_args]
    assert_equal 900, call[:options][:timeout]
    assert_equal false, call[:options][:fallback]
    assert_equal "abc123", call[:env_assign_id]
    assert_equal "010.01", call[:env_fork_root]
  end

  def test_launch_merges_required_and_user_cli_args
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 },
      "providers" => { "cli_args" => { "claude" => "dangerously-skip-permissions" } }
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(
      assignment_id: "abc123",
      fork_root: "010",
      cli_args: "--model-settings x"
    )

    call = fake.calls.last
    assert_equal "dangerously-skip-permissions --model-settings x", call[:options][:cli_args]
  end
end
