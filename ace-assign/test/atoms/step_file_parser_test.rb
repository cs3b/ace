# frozen_string_literal: true

require_relative "../test_helper"

class StepFileParserTest < AceAssignTestCase
  def test_parse_with_frontmatter
    content = <<~MD
      ---
      name: init-project
      status: pending
      ---

      # Instructions

      Do the thing.
    MD

    result = Ace::Assign::Atoms::StepFileParser.parse(content)

    assert_equal({"name" => "init-project", "status" => "pending"}, result[:frontmatter])
    assert_equal "# Instructions\n\nDo the thing.", result[:body]
  end

  def test_parse_without_frontmatter
    content = "# Just content\n\nNo frontmatter here."

    result = Ace::Assign::Atoms::StepFileParser.parse(content)

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

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)

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

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal "implement", result[:name]
    assert_equal :pending, result[:status]
    assert_equal "fork", result[:context]
    assert_equal "Implement the feature.", result[:instructions]
  end

  def test_extract_fields_with_fork_pid_metadata
    parsed = {
      frontmatter: {
        "name" => "work-on-task",
        "status" => "in_progress",
        "fork_launch_pid" => "355349",
        "fork_tracked_pids" => %w[355366 355367],
        "fork_pid_updated_at" => "2026-02-25T18:30:00Z",
        "fork_pid_file" => "/tmp/010.pid.yml"
      },
      body: "Execute in fork context."
    }

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal 355_349, result[:fork_launch_pid]
    assert_equal [355_366, 355_367], result[:fork_tracked_pids]
    assert_equal Time.utc(2026, 2, 25, 18, 30, 0), result[:fork_pid_updated_at]
    assert_equal "/tmp/010.pid.yml", result[:fork_pid_file]
  end

  def test_extract_fields_with_batch_scheduler_metadata
    parsed = {
      frontmatter: {
        "name" => "batch-items",
        "status" => "pending",
        "batch_parent" => true,
        "parallel" => true,
        "max_parallel" => "3",
        "fork_retry_limit" => "1"
      },
      body: "Batch orchestration."
    }

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)

    assert_equal true, result[:batch_parent]
    assert_equal true, result[:parallel]
    assert_equal 3, result[:max_parallel]
    assert_equal 1, result[:fork_retry_limit]
  end

  def test_extract_fields_without_context
    parsed = {
      frontmatter: {
        "name" => "init",
        "status" => "pending"
      },
      body: "Initialize."
    }

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)

    assert_nil result[:context]
  end

  def test_extract_instructions
    body = "Just instructions here."
    result = Ace::Assign::Atoms::StepFileParser.extract_instructions(body)
    assert_equal "Just instructions here.", result
  end

  def test_parse_filename_main
    result = Ace::Assign::Atoms::StepFileParser.parse_filename("010-init-project.st.md")
    assert_equal({number: "010", name: "init-project", parent: nil}, result)
  end

  def test_parse_filename_subtask
    result = Ace::Assign::Atoms::StepFileParser.parse_filename("010.01-setup-dirs.st.md")
    assert_equal({number: "010.01", name: "setup-dirs", parent: "010"}, result)
  end

  def test_parse_filename_deeply_nested
    result = Ace::Assign::Atoms::StepFileParser.parse_filename("010.01.02-verify.st.md")
    assert_equal({number: "010.01.02", name: "verify", parent: "010.01"}, result)
  end

  def test_parse_filename_report
    result = Ace::Assign::Atoms::StepFileParser.parse_filename("010-init-project.r.md")
    assert_equal({number: "010", name: "init-project", parent: nil}, result)
  end

  def test_parse_filename_nested_report
    result = Ace::Assign::Atoms::StepFileParser.parse_filename("010.01-setup-dirs.r.md")
    assert_equal({number: "010.01", name: "setup-dirs", parent: "010"}, result)
  end

  def test_generate_filename
    result = Ace::Assign::Atoms::StepFileParser.generate_filename("030", "Build Project")
    assert_equal "030-build-project.st.md", result
  end

  def test_generate_filename_sanitizes
    result = Ace::Assign::Atoms::StepFileParser.generate_filename("030", "Build/Test Project!")
    assert_equal "030-build-test-project.st.md", result
  end

  def test_generate_report_filename
    result = Ace::Assign::Atoms::StepFileParser.generate_report_filename("030", "Build Project")
    assert_equal "030-build-project.r.md", result
  end

  def test_generate_report_filename_sanitizes
    result = Ace::Assign::Atoms::StepFileParser.generate_report_filename("030", "Build/Test Project!")
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
      Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)
    end

    assert_match(/Invalid context 'frok'/, error.message)
    assert_match(/fork/, error.message)
  end

  def test_extract_fields_parses_stall_reason
    parsed = {
      frontmatter: {
        "name" => "release",
        "status" => "in_progress",
        "stall_reason" => "I encountered an unexpected state."
      },
      body: "Release instructions."
    }

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)
    assert_equal "I encountered an unexpected state.", result[:stall_reason]
  end

  def test_extract_fields_stall_reason_nil_when_absent
    parsed = {
      frontmatter: {
        "name" => "release",
        "status" => "in_progress"
      },
      body: "Release instructions."
    }

    result = Ace::Assign::Atoms::StepFileParser.extract_fields(parsed)
    assert_nil result[:stall_reason]
  end
end
