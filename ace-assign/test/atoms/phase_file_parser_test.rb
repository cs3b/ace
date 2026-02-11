# frozen_string_literal: true

require_relative "../test_helper"

class PhaseFileParserTest < AceAssignTestCase
  def test_parse_with_frontmatter
    content = <<~MD
      ---
      name: init-project
      status: pending
      ---

      # Instructions

      Do the thing.
    MD

    result = Ace::Assign::Atoms::PhaseFileParser.parse(content)

    assert_equal({ "name" => "init-project", "status" => "pending" }, result[:frontmatter])
    assert_equal "# Instructions\n\nDo the thing.", result[:body]
  end

  def test_parse_without_frontmatter
    content = "# Just content\n\nNo frontmatter here."

    result = Ace::Assign::Atoms::PhaseFileParser.parse(content)

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

    result = Ace::Assign::Atoms::PhaseFileParser.extract_fields(parsed)

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

    result = Ace::Assign::Atoms::PhaseFileParser.extract_fields(parsed)

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

    result = Ace::Assign::Atoms::PhaseFileParser.extract_fields(parsed)

    assert_nil result[:context]
  end

  def test_extract_instructions
    body = "Just instructions here."
    result = Ace::Assign::Atoms::PhaseFileParser.extract_instructions(body)
    assert_equal "Just instructions here.", result
  end

  def test_parse_filename_main
    result = Ace::Assign::Atoms::PhaseFileParser.parse_filename("010-init-project.ph.md")
    assert_equal({ number: "010", name: "init-project", parent: nil }, result)
  end

  def test_parse_filename_subtask
    result = Ace::Assign::Atoms::PhaseFileParser.parse_filename("010.01-setup-dirs.ph.md")
    assert_equal({ number: "010.01", name: "setup-dirs", parent: "010" }, result)
  end

  def test_parse_filename_deeply_nested
    result = Ace::Assign::Atoms::PhaseFileParser.parse_filename("010.01.02-verify.ph.md")
    assert_equal({ number: "010.01.02", name: "verify", parent: "010.01" }, result)
  end

  def test_parse_filename_report
    result = Ace::Assign::Atoms::PhaseFileParser.parse_filename("010-init-project.r.md")
    assert_equal({ number: "010", name: "init-project", parent: nil }, result)
  end

  def test_parse_filename_nested_report
    result = Ace::Assign::Atoms::PhaseFileParser.parse_filename("010.01-setup-dirs.r.md")
    assert_equal({ number: "010.01", name: "setup-dirs", parent: "010" }, result)
  end

  def test_generate_filename
    result = Ace::Assign::Atoms::PhaseFileParser.generate_filename("030", "Build Project")
    assert_equal "030-build-project.ph.md", result
  end

  def test_generate_filename_sanitizes
    result = Ace::Assign::Atoms::PhaseFileParser.generate_filename("030", "Build/Test Project!")
    assert_equal "030-build-test-project.ph.md", result
  end

  def test_generate_report_filename
    result = Ace::Assign::Atoms::PhaseFileParser.generate_report_filename("030", "Build Project")
    assert_equal "030-build-project.r.md", result
  end

  def test_generate_report_filename_sanitizes
    result = Ace::Assign::Atoms::PhaseFileParser.generate_report_filename("030", "Build/Test Project!")
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
      Ace::Assign::Atoms::PhaseFileParser.extract_fields(parsed)
    end

    assert_match(/Invalid context 'frok'/, error.message)
    assert_match(/fork/, error.message)
  end
end
