# frozen_string_literal: true

require_relative "../../test_helper"

class LocalProcessInspectorTest < Minitest::Test
  def test_finds_matching_direct_child_command
    inspector = Ace::Tmux::Molecules::LocalProcessInspector.new(
      command_runner: lambda do |cmd|
        stdout = cmd.last == "10" ? "11 10 codex\n" : ""
        {success: true, stdout: stdout, stderr: ""}
      end
    )

    assert_equal "codex", inspector.find_descendant_command("10", allowed_commands: %w[codex claude pi])
  end

  def test_walks_nested_children_to_find_supported_command
    inspector = Ace::Tmux::Molecules::LocalProcessInspector.new(
      command_runner: lambda do |cmd|
        stdout =
          case cmd.last
          when "10" then "11 10 fish\n"
          when "11" then "12 11 claude\n"
          else ""
          end

        {success: true, stdout: stdout, stderr: ""}
      end
    )

    assert_equal "claude", inspector.find_descendant_command("10", allowed_commands: %w[codex claude pi])
  end

  def test_returns_nil_when_process_lookup_fails
    inspector = Ace::Tmux::Molecules::LocalProcessInspector.new(
      command_runner: ->(_cmd) { {success: false, stdout: "", stderr: "ps failed"} }
    )

    assert_nil inspector.find_descendant_command("10", allowed_commands: %w[codex claude pi])
  end
end
