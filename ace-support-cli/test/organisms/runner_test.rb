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
end
