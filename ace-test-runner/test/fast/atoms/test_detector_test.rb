# frozen_string_literal: true

require "test_helper"

class TestDetectorTest < Minitest::Test
  def setup
    @detector = Ace::TestRunner::Atoms::TestDetector.new
  end

  def test_finds_test_files_with_default_patterns
    with_temp_dir do |dir|
      # Create test files
      FileUtils.mkdir_p("test/unit")
      File.write("test/unit/example_test.rb", "# test file")
      File.write("test/test_helper.rb", "# helper")

      FileUtils.mkdir_p("spec")
      File.write("spec/example_spec.rb", "# spec file")

      # Create non-test files
      FileUtils.mkdir_p("lib")
      File.write("lib/example.rb", "# source file")

      files = @detector.find_test_files

      # Filter out test_helper.rb for assertion
      actual_test_files = files.reject { |f| f.include?("test_helper.rb") }

      assert_equal 2, actual_test_files.size
      assert actual_test_files.any? { |f| f.include?("example_test.rb") }
      assert actual_test_files.any? { |f| f.include?("example_spec.rb") }
    end
  end

  def test_filters_by_pattern
    files = [
      "test/user_test.rb",
      "test/admin_test.rb",
      "test/helper_test.rb"
    ]

    filtered = @detector.filter_by_pattern(files, "user")
    assert_equal 1, filtered.size
    assert_equal "test/user_test.rb", filtered.first
  end

  def test_detects_test_file
    with_temp_dir do
      File.write("test_example.rb", "")
      File.write("example.rb", "")

      detector = Ace::TestRunner::Atoms::TestDetector.new(patterns: ["test_*.rb"])
      assert detector.test_file?("test_example.rb")
      refute detector.test_file?("example.rb")
    end
  end

  def test_returns_empty_array_when_no_tests_found
    with_temp_dir do
      files = @detector.find_test_files
      assert_empty files
    end
  end

  def test_removes_duplicate_files
    with_temp_dir do
      FileUtils.mkdir_p("test")
      File.write("test/example_test.rb", "")

      detector = Ace::TestRunner::Atoms::TestDetector.new(
        patterns: ["test/**/*_test.rb", "test/*_test.rb", "test/**/*test.rb"]
      )

      files = detector.find_test_files
      assert_equal 1, files.size
    end
  end
end
