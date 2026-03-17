# frozen_string_literal: true

require_relative "../test_helper"

class RunnerTest < AceSupportCliTestCase
  class RunCommand < Ace::Support::Cli::Command
    option :count, type: :integer

    def call(**params)
      params
    end
  end

  def test_dispatches_with_typed_options
    registry = Ace::Support::Cli::Registry.new
    registry.register("run", RunCommand)

    result = Ace::Support::Cli::Runner.new(registry).call(args: %w[run --count 4])

    assert_equal 4, result[:count]
  end

  class ShowCommand < Ace::Support::Cli::Command
    desc "Show task details"
    option :format, type: :string, default: "text"
    argument :id, type: :integer, required: true
    example ["42"]

    def call(**_params) = nil
  end

  def test_help_flag_renders_rich_help_with_correct_command_name
    registry = Ace::Support::Cli::Registry.new
    registry.register("show", ShowCommand)

    runner = Ace::Support::Cli::Runner.new(registry)
    output = capture_io do
      assert_raises(SystemExit) { runner.call(args: %w[show --help]) }
    end.first

    assert_includes output, "NAME"
    assert_includes output, "show"
    assert_includes output, "Show task details"
  end
end
