# frozen_string_literal: true

require_relative "../../test_helper"

class CommandTest < AceSupportCliTestCase
  class ExampleCommand < Ace::Support::Cli::Command
    desc "Demo"
    option :verbose, type: :boolean, default: false, aliases: ["-v"], repeat: true
    argument :name, required: true
    example ["demo --verbose bob"]

    def call(**params)
      params
    end
  end

  class ChildCommand < ExampleCommand
    option :count, type: :integer, default: 1
  end

  def test_collects_dsl_metadata
    assert_equal "Demo", ExampleCommand.description
    assert_equal 1, ExampleCommand.options.length
    assert_equal 1, ExampleCommand.arguments.length
    assert_equal ["demo --verbose bob"], ExampleCommand.examples
    assert_equal true, ExampleCommand.options.first.repeat
  end

  def test_inherited_metadata_is_copied
    assert_equal 2, ChildCommand.options.length
    assert_equal 1, ExampleCommand.options.length
  end
end
