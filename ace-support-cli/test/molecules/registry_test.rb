# frozen_string_literal: true

require_relative "../test_helper"

class RegistryTest < AceSupportCliTestCase
  class LintCommand < Ace::Support::Cli::Command
    def call(**params)
      params
    end
  end

  class TestAtomsCommand < Ace::Support::Cli::Command
    def call(**params)
      params
    end
  end

  def test_resolves_top_level_command
    registry = Ace::Support::Cli::Registry.new
    registry.register("lint", LintCommand)

    command, remaining = registry.resolve(%w[lint --verbose])

    assert_equal LintCommand, command
    assert_equal ["--verbose"], remaining
  end

  def test_resolves_nested_commands
    registry = Ace::Support::Cli::Registry.new
    registry.register("test") do |r|
      r.register("atoms", TestAtomsCommand)
    end

    command, remaining = registry.resolve(%w[test atoms --count 2])

    assert_equal TestAtomsCommand, command
    assert_equal ["--count", "2"], remaining
  end

  def test_raises_for_missing_command
    registry = Ace::Support::Cli::Registry.new

    error = assert_raises(Ace::Support::Cli::CommandNotFoundError) do
      registry.resolve(%w[lint])
    end

    assert_includes error.message, "No commands"
  end
end
