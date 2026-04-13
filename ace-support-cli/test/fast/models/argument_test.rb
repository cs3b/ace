# frozen_string_literal: true

require_relative "../../test_helper"

class ArgumentTest < AceSupportCliTestCase
  def test_initializes_with_defaults
    argument = Ace::Support::Cli::Models::Argument.new(name: :count, type: :integer, required: false)

    assert_equal :count, argument.name
    assert_equal :integer, argument.type
    assert_equal false, argument.required
  end

  def test_rejects_unknown_type
    error = assert_raises(ArgumentError) do
      Ace::Support::Cli::Models::Argument.new(name: :x, type: :object)
    end

    assert_includes error.message, "Invalid argument type"
  end
end
