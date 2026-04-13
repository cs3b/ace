# frozen_string_literal: true

require_relative "../../test_helper"

class OptionTest < AceSupportCliTestCase
  def test_initializes_with_defaults
    option = Ace::Support::Cli::Models::Option.new(name: :limit, type: :integer, aliases: [:l], required: true)

    assert_equal :limit, option.name
    assert_equal :integer, option.type
    assert_equal ["-l"], option.aliases
    assert_equal "--limit", option.long_switch
    assert_equal true, option.required
  end

  def test_rejects_unknown_type
    error = assert_raises(ArgumentError) do
      Ace::Support::Cli::Models::Option.new(name: :x, type: :unknown)
    end

    assert_includes error.message, "Invalid option type"
  end
end
