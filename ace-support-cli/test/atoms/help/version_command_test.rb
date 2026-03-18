# frozen_string_literal: true

require "stringio"
require_relative "../../test_helper"

class VersionCommandFactoryTest < AceSupportCliTestCase
  def test_build_outputs_name_and_version
    command_class = Ace::Support::Cli::VersionCommand.build(gem_name: "ace-tool", version: "1.2.3")

    stdout = capture_stdout { assert_equal 0, command_class.new.call }
    assert_equal "ace-tool 1.2.3\n", stdout
  end

  def test_module_show_version_outputs_correctly
    version_module = Ace::Support::Cli::VersionCommand.module(gem_name: "dynamic-gem", version: -> { "3.2.1" })
    klass = Class.new { include version_module }

    stdout = capture_stdout do
      result = klass.new.show_version
      assert_equal 0, result
    end

    assert_includes stdout, "dynamic-gem 3.2.1"
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
