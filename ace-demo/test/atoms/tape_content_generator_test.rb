# frozen_string_literal: true

require_relative "../test_helper"

class TapeContentGeneratorTest < AceDemoTestCase
  def test_generates_basic_tape
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "my-demo",
      commands: ["echo hello"]
    )

    assert_includes content, "Output .ace-local/demo/my-demo.gif"
    assert_includes content, "Set FontSize 16"
    assert_includes content, "Set Width 960"
    assert_includes content, "Set Height 480"
    assert_includes content, 'Type "echo hello"'
    assert_includes content, "Enter"
    assert_includes content, "Sleep 2s"
  end

  def test_generates_with_metadata
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "deploy",
      commands: ["make deploy"],
      description: "Deploy flow",
      tags: "ci, deploy"
    )

    assert_includes content, "# Description: Deploy flow"
    assert_includes content, "# Tags: ci, deploy"
  end

  def test_generates_multiple_commands
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "multi",
      commands: ["git status", "make deploy"]
    )

    assert_includes content, 'Type "git status"'
    assert_includes content, 'Type "make deploy"'
    assert_equal 2, content.scan("Enter").length
    assert_equal 2, content.scan("Sleep 2s").length
  end

  def test_uses_custom_settings
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "custom",
      commands: ["echo hi"],
      font_size: 18,
      width: 1200,
      height: 600,
      timeout: "3s"
    )

    assert_includes content, "Set FontSize 18"
    assert_includes content, "Set Width 1200"
    assert_includes content, "Set Height 600"
    assert_includes content, "Sleep 3s"
  end

  def test_uses_custom_output_path
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "custom",
      commands: ["echo hi"],
      output_path: ".ace-local/demo/custom.mp4"
    )

    assert_includes content, "Output .ace-local/demo/custom.mp4"
  end

  def test_escapes_double_quotes_and_backslashes
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "escape",
      commands: ['echo "hello\\world"']
    )

    assert_includes content, 'Type "echo \\"hello\\\\world\\""'
  end

  def test_omits_metadata_when_not_provided
    content = Ace::Demo::Atoms::TapeContentGenerator.generate(
      name: "bare",
      commands: ["echo hi"]
    )

    refute_includes content, "# Description:"
    refute_includes content, "# Tags:"
  end
end
