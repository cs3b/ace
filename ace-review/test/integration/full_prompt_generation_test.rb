# frozen_string_literal: true

require "test_helper"

class FullPromptGenerationTest < AceReviewTest
  def setup
    super  # IMPORTANT: Call parent to stub ace-context for fast tests
    @manager = Ace::Review::Organisms::ReviewManager.new
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super  # IMPORTANT: Call parent to restore ace-context
  end

  def test_system_prompt_includes_embedded_sections_from_preset
    # Use the docs preset which has multiple sections
    options = {
      preset: "docs",
      subject: "# Sample Documentation\n\nThis is test content.",
      context: { "files" => [] },  # Empty context to avoid preset dependencies
      auto_execute: false,
      session_dir: @temp_dir
    }

    result = @manager.execute_review(options)

    # Verify review preparation succeeded
    assert result[:success], "Review preparation should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    # Verify system.prompt.md exists and has substantial content
    system_prompt_path = File.join(result[:session_dir], "system.prompt.md")
    assert File.exist?(system_prompt_path), "system.prompt.md should exist"

    system_prompt = File.read(system_prompt_path)

    # Verify sections are embedded (not just referenced)
    assert system_prompt.length > 1000,
           "System prompt should be substantial (>1000 chars), got #{system_prompt.length} chars"

    # Verify it contains the base prompt
    assert_match(/code review/i, system_prompt, "Should contain base review prompt")

    # Verify it contains section content (not just references)
    # The docs preset includes format, docs_focus, and communication sections
    assert_match(/<format>/, system_prompt, "Should contain format section XML tag")
    assert_match(/Format Guidelines/, system_prompt, "Should contain format section title")
    assert_match(/Documentation Review Focus/, system_prompt, "Should contain docs focus section")
    assert_match(/Communication Style/, system_prompt, "Should contain communication section")

    # Verify actual section content is embedded (not just the section header)
    assert_match(/Output Formatting Rules/i, system_prompt,
                 "Should contain actual section content from format guidelines")
  end
end
