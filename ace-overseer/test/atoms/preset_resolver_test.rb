# frozen_string_literal: true

require_relative "../test_helper"

class PresetResolverTest < AceOverseerTestCase
  def test_prefers_task_frontmatter_preset
    value = Ace::Overseer::Atoms::PresetResolver.resolve(
      task_frontmatter: {"assign" => {"preset" => "task-preset"}},
      cli_preset: "cli-preset",
      default: "default-preset"
    )

    assert_equal "task-preset", value
  end

  def test_falls_back_to_cli_preset_then_default
    from_cli = Ace::Overseer::Atoms::PresetResolver.resolve(
      task_frontmatter: {},
      cli_preset: "cli-preset",
      default: "default-preset"
    )
    from_default = Ace::Overseer::Atoms::PresetResolver.resolve(
      task_frontmatter: {},
      cli_preset: nil,
      default: "default-preset"
    )

    assert_equal "cli-preset", from_cli
    assert_equal "default-preset", from_default
  end

  def test_supports_symbol_keys
    value = Ace::Overseer::Atoms::PresetResolver.resolve(
      task_frontmatter: {assign: {preset: "symbol-preset"}},
      cli_preset: nil,
      default: "default"
    )

    assert_equal "symbol-preset", value
  end
end
