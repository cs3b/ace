# frozen_string_literal: true

require "stringio"
require_relative "../../test_helper"

class VersionCommandFactoryTest < AceSupportCliTestCase
  def test_build_outputs_name_and_version
    command_class = Ace::Support::Cli::VersionCommand.build(gem_name: "ace-tool", version: "1.2.3")

    stdout = capture_stdout { assert_equal 0, command_class.new.call }
    assert_equal "ace-tool 1.2.3\n", stdout
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
