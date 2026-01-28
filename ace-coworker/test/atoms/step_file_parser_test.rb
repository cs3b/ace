# frozen_string_literal: true

require_relative "../test_helper"

class StepFileParserTest < AceCoworkerTestCase
  def test_parse_with_frontmatter
    content = <<~MD
      ---
      name: init-project
      status: pending
      ---

      # Instructions

      Do the thing.
    MD

    result = Ace::Coworker::Atoms::StepFileParser.parse(content)

    assert_equal({ "name" => "init-project", "status" => "pending" }, result[:frontmatter])
    assert_equal "# Instructions\n\nDo the thing.", result[:body]
  end

  def test_parse_without_frontmatter
    content = "# Just content\n\nNo frontmatter here."

    result = Ace::Coworker::Atoms::StepFileParser.parse(content)

    assert_equal({}, result[:frontmatter])
    assert_equal "# Just content\n\nNo frontmatter here.", result[:body]
  end

  def test_extract_fields
    parsed = {
      frontmatter: {
        "name" => "build",
        "status" => "in_progress",
        "error" => nil,
        "added_by" => "dynamic"
      },
      body: "Build the project.\n\n---\n\n# Report\n\nBuild succeeded."
    }

    result = Ace::Coworker::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal "build", result[:name]
    assert_equal :in_progress, result[:status]
    assert_equal "Build the project.", result[:instructions]
    assert_equal "Build succeeded.", result[:report]
    assert_equal "dynamic", result[:added_by]
  end

  def test_extract_instructions_without_report
    body = "Just instructions here."
    result = Ace::Coworker::Atoms::StepFileParser.extract_instructions(body)
    assert_equal "Just instructions here.", result
  end

  def test_extract_instructions_with_report
    body = "Instructions\n\n---\n\n# Report\n\nReport content"
    result = Ace::Coworker::Atoms::StepFileParser.extract_instructions(body)
    assert_equal "Instructions", result
  end

  def test_extract_report_when_present
    body = "Instructions\n\n---\n\n# Report\n\nReport content"
    result = Ace::Coworker::Atoms::StepFileParser.extract_report(body)
    assert_equal "Report content", result
  end

  def test_extract_report_when_absent
    body = "Just instructions"
    result = Ace::Coworker::Atoms::StepFileParser.extract_report(body)
    assert_nil result
  end

  def test_parse_filename_main
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010-init-project.md")
    assert_equal({ number: "010", name: "init-project" }, result)
  end

  def test_parse_filename_subtask
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010.01-setup-dirs.md")
    assert_equal({ number: "010.01", name: "setup-dirs" }, result)
  end

  def test_generate_filename
    result = Ace::Coworker::Atoms::StepFileParser.generate_filename("030", "Build Project")
    assert_equal "030-build-project.md", result
  end

  def test_generate_filename_sanitizes
    result = Ace::Coworker::Atoms::StepFileParser.generate_filename("030", "Build/Test Project!")
    assert_equal "030-build-test-project.md", result
  end
end
