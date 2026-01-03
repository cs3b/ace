# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class CliApiParityTest < AceTestCase
  def setup
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def test_cli_and_api_produce_identical_output_for_file_with_sections
    # Create a test context file with sections that should be embedded
    context_file = File.join(@temp_dir, "test-context.md")
    context_content = <<~CONTEXT
      ---
      context:
        base: "Base prompt content"
        sections:
          format:
            title: "Format Guidelines"
            files:
              - "prompt://format/standard"
          tone:
            title: "Communication Style"
            files:
              - "prompt://guidelines/tone"
      ---
    CONTEXT
    File.write(context_file, context_content)

    # Get CLI output
    cli_output = `ace-context "#{context_file}" 2>&1`
    cli_exit_code = $?.exitstatus

    # Get API output
    api_result = Ace::Context.load_file(context_file)
    api_output = api_result.content

    # Both should succeed
    assert_equal 0, cli_exit_code, "CLI should execute successfully"
    refute api_result.metadata[:error], "API should not have errors: #{api_result.metadata[:error]}"

    # Outputs should be identical
    assert_equal cli_output.strip, api_output.strip,
                 "CLI and API outputs should be identical"

    # Both should have embedded sections (not just references)
    assert api_output.length > 500, "Content should be substantial (has embedded sections)"
    assert_match(/Base prompt content/, api_output, "Should contain base content")

    # Verify sections are embedded (should contain actual section content, not just references)
    assert_match(/<format>/, api_output, "Should contain format section XML tag")
    assert_match(/Format Guidelines/, api_output, "Should contain section title")
  end
end
