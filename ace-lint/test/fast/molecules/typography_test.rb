# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::TypographyTest < Minitest::Test
  def setup
    @linter = Ace::Lint::Molecules::MarkdownLinter
    @default_config = {"typography" => {"em_dash" => "warn", "smart_quotes" => "warn"}}
  end

  # Em-dash detection tests
  def test_detects_em_dash_with_line_number
    content = "This is a test\nHere is an em-dash\u2014in the middle\nMore text\n"
    issues = @linter.check_typography(content, @default_config)

    assert_equal 1, issues.size
    assert_equal 2, issues.first.line
    assert_match(/Em-dash character found/, issues.first.message)
    assert_equal :warning, issues.first.severity
  end

  def test_detects_multiple_em_dashes_on_same_line
    content = "Text\u2014more\u2014text\n"
    issues = @linter.check_typography(content, @default_config)

    # Should report one issue per line (not per character)
    assert_equal 1, issues.size
    assert_equal 1, issues.first.line
  end

  def test_em_dash_with_error_severity
    content = "Text with em-dash\u2014here\n"
    config = {"typography" => {"em_dash" => "error", "smart_quotes" => "off"}}
    issues = @linter.check_typography(content, config)

    assert_equal 1, issues.size
    assert_equal :error, issues.first.severity
  end

  def test_em_dash_disabled_when_off
    content = "Text with em-dash\u2014here\n"
    config = {"typography" => {"em_dash" => "off", "smart_quotes" => "off"}}
    issues = @linter.check_typography(content, config)

    assert_empty issues
  end

  # Smart quote detection tests
  def test_detects_left_double_quote
    content = "He said \u201Chello\u201D\n"
    issues = @linter.check_typography(content, @default_config)

    # Should detect both left and right double quotes
    assert_equal 2, issues.size
    assert(issues.all? { |i| i.message.include?("Smart double quote") })
  end

  def test_detects_right_double_quote
    content = "Testing\u201D only\n"
    issues = @linter.check_typography(content, @default_config)

    assert_equal 1, issues.size
    assert_match(/Smart double quote/, issues.first.message)
  end

  def test_detects_left_single_quote
    content = "The word \u2018test\u2019\n"
    issues = @linter.check_typography(content, @default_config)

    # Should detect both left and right single quotes
    assert_equal 2, issues.size
    assert(issues.all? { |i| i.message.include?("Smart single quote") })
  end

  def test_detects_right_single_quote
    content = "It\u2019s a test\n"
    issues = @linter.check_typography(content, @default_config)

    assert_equal 1, issues.size
    assert_match(/Smart single quote/, issues.first.message)
  end

  def test_smart_quotes_with_error_severity
    content = "He said \u201Chello\u201D\n"
    config = {"typography" => {"em_dash" => "off", "smart_quotes" => "error"}}
    issues = @linter.check_typography(content, config)

    assert_equal 2, issues.size
    assert(issues.all? { |i| i.severity == :error })
  end

  def test_smart_quote_message_includes_actual_character
    content = "Quote \u201Chere\u201D\n"
    issues = @linter.check_typography(content, @default_config)

    left_quote_issue = issues.find { |i| i.message.include?("\u201C") }
    right_quote_issue = issues.find { |i| i.message.include?("\u201D") }

    assert left_quote_issue, "Should include left quote character in message"
    assert right_quote_issue, "Should include right quote character in message"
  end

  def test_smart_quotes_disabled_when_off
    content = "He said \u201Chello\u201D and \u2018goodbye\u2019\n"
    config = {"typography" => {"em_dash" => "warn", "smart_quotes" => "off"}}
    issues = @linter.check_typography(content, config)

    assert_empty issues
  end

  # Code block skipping tests
  def test_skips_fenced_code_blocks
    content = <<~MARKDOWN
      Normal text

      ```ruby
      puts "This has em-dash\u2014inside code"
      puts "And smart quotes \u201Chere\u201D"
      ```

      More normal text
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_skips_multiple_fenced_code_blocks
    content = <<~MARKDOWN
      Text before

      ```
      code block 1 with em-dash\u2014
      ```

      Text between

      ```python
      code block 2 with quotes \u201Ctest\u201D
      ```

      Text after
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_skips_tilde_fenced_code_blocks
    content = <<~MARKDOWN
      Normal text

      ~~~ruby
      puts "This has em-dash\u2014inside tilde fence"
      puts "And smart quotes \u201Chere\u201D"
      ~~~

      More normal text
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_skips_indented_fenced_code_blocks
    content = <<~MARKDOWN
      Normal text

         ```
         code with em-dash\u2014 and quotes \u201Chere\u201D
         ```

      More text
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_detects_issues_outside_code_blocks
    content = <<~MARKDOWN
      Problem em-dash\u2014here

      ```
      safe code with em-dash\u2014
      ```

      Another problem\u2014after
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    assert_equal 2, issues.size
    assert_equal 1, issues[0].line
    assert_equal 7, issues[1].line
  end

  # Inline code skipping tests
  def test_skips_inline_code
    content = "Text with `code\u2014here` more text\n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_skips_multiple_inline_code_spans
    content = "Has `code\u2014one` and `code\u201Ctwo\u201D` spans\n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_detects_issues_outside_inline_code
    content = "Problem\u2014before `safe\u2014code` and problem\u2014after\n"
    issues = @linter.check_typography(content, @default_config)

    # Should detect em-dashes outside inline code only (one issue per line)
    assert_equal 1, issues.size
    assert(issues.all? { |i| i.message.include?("Em-dash") })
  end

  def test_skips_double_backtick_inline_code
    content = "Text with ``code\u2014here`` more text\n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_skips_double_backtick_with_single_inside
    content = "Text with ``code `nested` here\u2014`` more text\n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  # Markdown link handling tests
  def test_skips_link_url_but_checks_link_text
    content = "Check [link text](https://example.com/path\u2014here)\n"
    issues = @linter.check_typography(content, @default_config)

    # URL should be stripped, link text should be checked (no issues in link text)
    assert_empty issues
  end

  def test_skips_link_url_with_nested_parentheses
    content = "Check [link text](https://example.com/a(b)c\u2014d)\n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_detects_issues_in_link_text
    content = "See [link\u2014text](https://example.com)\n"
    issues = @linter.check_typography(content, @default_config)

    assert_equal 1, issues.size
    assert_match(/Em-dash/, issues.first.message)
  end

  def test_skips_quoted_link_text_correctly
    content = "Click [See \"here\"](https://example.com) for info\n"
    issues = @linter.check_typography(content, @default_config)

    # ASCII quotes in link text should not trigger issues
    assert_empty issues
  end

  def test_detects_smart_quotes_in_link_text
    content = "See [\u201Cquoted\u201D](https://example.com)\n"
    issues = @linter.check_typography(content, @default_config)

    assert_equal 2, issues.size
    assert(issues.all? { |i| i.message.include?("Smart double quote") })
  end

  # Fence matching tests
  def test_fence_matching_requires_same_char
    content = <<~MARKDOWN
      ```
      code with em-dash\u2014
      ~~~
      still in code block\u2014
      ```
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    # ~~~ should not close ``` block
    assert_empty issues
  end

  def test_fence_matching_requires_sufficient_length
    content = <<~MARKDOWN
      ````
      code with em-dash\u2014
      ```
      still in code block\u2014
      ````
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    # ``` (3) should not close ```` (4) block
    assert_empty issues
  end

  def test_fence_can_close_with_longer_fence
    content = <<~MARKDOWN
      ```
      code with em-dash\u2014
      ````
      outside now with em-dash\u2014
    MARKDOWN
    issues = @linter.check_typography(content, @default_config)

    # ```` (4) can close ``` (3) block
    assert_equal 1, issues.size
    assert_equal 4, issues.first.line
  end

  # Empty file handling
  def test_handles_empty_file
    content = ""
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  def test_handles_file_with_only_whitespace
    content = "   \n\n  \n"
    issues = @linter.check_typography(content, @default_config)

    assert_empty issues
  end

  # Multiple issues per line
  def test_multiple_different_issues_on_same_line
    content = "Em-dash\u2014and smart quote\u201Chere\u201D\n"
    issues = @linter.check_typography(content, @default_config)

    # 1 em-dash + 2 smart quotes = 3 issues
    assert_equal 3, issues.size
    assert_equal 1, issues.map(&:line).uniq.size # all on line 1
  end

  # Configuration edge cases
  def test_handles_missing_typography_config
    content = "Text with em-dash\u2014here\n"
    config = {}
    issues = @linter.check_typography(content, config)

    # Should use default "warn" severity
    assert_equal 1, issues.size
    assert_equal :warning, issues.first.severity
  end

  def test_handles_partial_typography_config
    content = "Em-dash\u2014and quote\u201Chere\u201D\n"
    config = {"typography" => {"em_dash" => "error"}}
    issues = @linter.check_typography(content, config)

    em_dash_issues = issues.select { |i| i.message.include?("Em-dash") }
    quote_issues = issues.select { |i| i.message.include?("quote") }

    assert_equal 1, em_dash_issues.size
    assert_equal :error, em_dash_issues.first.severity

    # smart_quotes should default to "warn"
    assert_equal 2, quote_issues.size
    assert(quote_issues.all? { |i| i.severity == :warning })
  end

  # Integration with lint_content
  def test_typography_issues_included_in_lint_result
    content = "Test with em-dash\u2014here\n"

    Ace::Lint.stub(:markdown_config, @default_config) do
      result = @linter.lint_content("test.md", content)

      assert_equal 1, result.warnings.count { |w| w.message.include?("Em-dash") }
    end
  end

  def test_typography_errors_affect_success_status
    content = "Test with em-dash\u2014here\n"
    error_config = {"typography" => {"em_dash" => "error", "smart_quotes" => "off"}}

    Ace::Lint.stub(:markdown_config, error_config) do
      result = @linter.lint_content("test.md", content)

      refute result.success?
      assert_equal 1, result.errors.count { |e| e.message.include?("Em-dash") }
    end
  end

  def test_typography_warnings_dont_affect_success_status
    content = "Test with em-dash\u2014here\n"

    Ace::Lint.stub(:markdown_config, @default_config) do
      result = @linter.lint_content("test.md", content)

      assert result.success?
      assert_equal 1, result.warnings.count { |w| w.message.include?("Em-dash") }
    end
  end
end
