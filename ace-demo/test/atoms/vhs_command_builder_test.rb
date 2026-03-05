# frozen_string_literal: true

require_relative "../test_helper"

class VhsCommandBuilderTest < AceDemoTestCase
  def test_builds_command_array
    cmd = Ace::Demo::Atoms::VhsCommandBuilder.build(
      tape_path: "/tmp/hello.tape",
      output_path: "/tmp/hello.gif"
    )

    assert_equal ["vhs", "/tmp/hello.tape", "--output", "/tmp/hello.gif"], cmd
  end
end
