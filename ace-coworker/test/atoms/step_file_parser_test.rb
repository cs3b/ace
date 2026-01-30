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
      body: "Build the project."
    }

    result = Ace::Coworker::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal "build", result[:name]
    assert_equal :in_progress, result[:status]
    assert_equal "Build the project.", result[:instructions]
    assert_nil result[:report] # Reports are now in separate files
    assert_equal "dynamic", result[:added_by]
  end

  def test_extract_fields_with_context_fork
    parsed = {
      frontmatter: {
        "name" => "implement",
        "status" => "pending",
        "context" => "fork"
      },
      body: "Implement the feature."
    }

    result = Ace::Coworker::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal "implement", result[:name]
    assert_equal :pending, result[:status]
    assert_equal "fork", result[:context]
    assert_equal "Implement the feature.", result[:instructions]
  end

  def test_extract_fields_without_context
    parsed = {
      frontmatter: {
        "name" => "init",
        "status" => "pending"
      },
      body: "Initialize."
    }

    result = Ace::Coworker::Atoms::StepFileParser.extract_fields(parsed)

    assert_nil result[:context]
  end

  def test_extract_instructions
    body = "Just instructions here."
    result = Ace::Coworker::Atoms::StepFileParser.extract_instructions(body)
    assert_equal "Just instructions here.", result
  end

  def test_parse_filename_main
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010-init-project.j.md")
    assert_equal({ number: "010", name: "init-project", parent: nil }, result)
  end

  def test_parse_filename_subtask
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010.01-setup-dirs.j.md")
    assert_equal({ number: "010.01", name: "setup-dirs", parent: "010" }, result)
  end

  def test_parse_filename_deeply_nested
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010.01.02-verify.j.md")
    assert_equal({ number: "010.01.02", name: "verify", parent: "010.01" }, result)
  end

  def test_parse_filename_report
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010-init-project.r.md")
    assert_equal({ number: "010", name: "init-project", parent: nil }, result)
  end

  def test_parse_filename_nested_report
    result = Ace::Coworker::Atoms::StepFileParser.parse_filename("010.01-setup-dirs.r.md")
    assert_equal({ number: "010.01", name: "setup-dirs", parent: "010" }, result)
  end

  def test_generate_filename
    result = Ace::Coworker::Atoms::StepFileParser.generate_filename("030", "Build Project")
    assert_equal "030-build-project.j.md", result
  end

  def test_generate_filename_sanitizes
    result = Ace::Coworker::Atoms::StepFileParser.generate_filename("030", "Build/Test Project!")
    assert_equal "030-build-test-project.j.md", result
  end

  def test_generate_report_filename
    result = Ace::Coworker::Atoms::StepFileParser.generate_report_filename("030", "Build Project")
    assert_equal "030-build-project.r.md", result
  end

  def test_generate_report_filename_sanitizes
    result = Ace::Coworker::Atoms::StepFileParser.generate_report_filename("030", "Build/Test Project!")
    assert_equal "030-build-test-project.r.md", result
  end

  def test_extract_fields_with_invalid_context_raises
    parsed = {
      frontmatter: {
        "name" => "implement",
        "status" => "pending",
        "context" => "frok" # typo
      },
      body: "Implement the feature."
    }

    error = assert_raises(ArgumentError) do
      Ace::Coworker::Atoms::StepFileParser.extract_fields(parsed)
    end

    assert_match(/Invalid context 'frok'/, error.message)
    assert_match(/fork/, error.message)
  end
end
