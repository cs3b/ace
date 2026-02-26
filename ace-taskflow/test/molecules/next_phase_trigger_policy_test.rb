# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/next_phase_trigger_policy"

class NextPhaseTriggerPolicyTest < AceTaskflowTestCase
  def test_manual_mode_runs_even_if_config_disabled
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new(
      config: {
        "review" => {
          "next_phase" => {
            "enabled" => false,
            "auto" => { "idea" => false, "task" => false }
          }
        }
      }
    )

    result = policy.resolve(source_type: "task", manual: true)
    assert_equal true, result[:enabled]
    assert_equal %w[plan], result[:modes]
  end

  def test_auto_mode_uses_config_defaults
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new(
      config: {
        "review" => {
          "next_phase" => {
            "enabled" => true,
            "auto" => { "idea" => true, "task" => false }
          }
        }
      }
    )

    task_result = policy.resolve(source_type: "task", manual: false)
    idea_result = policy.resolve(source_type: "idea", manual: false)

    assert_equal false, task_result[:enabled]
    assert_equal true, idea_result[:enabled]
    assert_equal %w[draft plan], idea_result[:modes]
  end

  def test_cli_enable_and_disable_are_mutually_exclusive
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new

    error = assert_raises(ArgumentError) do
      policy.resolve(source_type: "task", manual: false, cli_enable: true, cli_disable: true)
    end
    assert_includes error.message, "Cannot use --next-phase-review and --no-next-phase-review together"
  end

  def test_cli_modes_override_defaults
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new
    result = policy.resolve(source_type: "task", manual: true, cli_modes: "plan,work")

    assert_equal %w[plan work], result[:modes]
  end

  def test_task_default_modes_exclude_work_extension_by_default
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new(
      config: {
        "review" => {
          "next_phase" => {
            "enabled" => true,
            "auto" => { "task" => true }
          }
        }
      }
    )

    result = policy.resolve(source_type: "task", manual: true)
    assert_equal %w[plan], result[:modes]
  end

  def test_task_default_modes_include_work_when_extension_enabled
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new(
      config: {
        "review" => {
          "next_phase" => {
            "enabled" => true,
            "include_work_simulation" => true,
            "auto" => { "task" => true }
          }
        }
      }
    )

    result = policy.resolve(source_type: "task", manual: true)
    assert_equal %w[plan work], result[:modes]
  end

  def test_cli_modes_override_config_default_when_work_extension_enabled
    policy = Ace::Taskflow::Molecules::NextPhaseTriggerPolicy.new(
      config: {
        "review" => {
          "next_phase" => {
            "enabled" => true,
            "include_work_simulation" => true,
            "auto" => { "task" => true }
          }
        }
      }
    )

    result = policy.resolve(source_type: "task", manual: true, cli_modes: "plan")
    assert_equal %w[plan], result[:modes]
  end
end
