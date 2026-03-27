# frozen_string_literal: true

require_relative "../test_helper"

class AggCommandBuilderTest < AceDemoTestCase
  def test_builds_default_command_array
    cmd = Ace::Demo::Atoms::AggCommandBuilder.build(
      input_path: "/tmp/demo.cast",
      output_path: "/tmp/demo.gif"
    )

    assert_equal ["agg", "/tmp/demo.cast", "/tmp/demo.gif"], cmd
  end

  def test_builds_command_with_optional_flags
    cmd = Ace::Demo::Atoms::AggCommandBuilder.build(
      input_path: "/tmp/demo.cast",
      output_path: "/tmp/demo.gif",
      font_size: 18,
      theme: "dracula",
      font_family: "Hack Nerd Font Mono",
      agg_bin: "agg-custom"
    )

    assert_equal [
      "agg-custom",
      "--font-size",
      "18",
      "--theme",
      "dracula",
      "--font-family",
      "Hack Nerd Font Mono",
      "/tmp/demo.cast",
      "/tmp/demo.gif"
    ], cmd
  end
end
