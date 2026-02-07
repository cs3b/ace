# frozen_string_literal: true

require_relative "../test_helper"

class TestDiscovererTest < Minitest::Test
  def setup
    @discoverer = Ace::Test::EndToEndRunner::Molecules::TestDiscoverer.new
    @base_dir = File.expand_path("../../..", __dir__)
  end

  def test_find_tests_for_existing_package
    files = @discoverer.find_tests(package: "ace-lint", base_dir: @base_dir)
    refute_empty files, "Should find E2E tests in ace-lint"
    assert files.all? { |f| f.end_with?(".mt.md") }, "All files should be .mt.md"
  end

  def test_find_tests_for_nonexistent_package
    files = @discoverer.find_tests(package: "ace-nonexistent", base_dir: @base_dir)
    assert_empty files, "Should find no tests for nonexistent package"
  end

  def test_find_specific_test_by_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "MT-LINT-001",
      base_dir: @base_dir
    )
    assert_equal 1, files.size, "Should find exactly one test for MT-LINT-001"
    assert files.first.include?("MT-LINT-001"), "File should contain test ID"
  end

  def test_find_specific_test_nonexistent_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "MT-LINT-999",
      base_dir: @base_dir
    )
    assert_empty files, "Should find no tests for nonexistent ID"
  end

  def test_find_tests_returns_sorted
    files = @discoverer.find_tests(package: "ace-lint", base_dir: @base_dir)
    assert_equal files.sort, files, "Results should be sorted"
  end

  def test_list_packages
    packages = @discoverer.list_packages(base_dir: @base_dir)
    refute_empty packages, "Should find packages with E2E tests"
    assert_includes packages, "ace-lint", "Should include ace-lint"
  end

  def test_find_tests_in_temp_directory
    Dir.mktmpdir do |tmpdir|
      # Create test structure
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-example.mt.md"), "---\ntest-id: MT-TEST-001\n---\n")
      File.write(File.join(test_dir, "MT-TEST-002-other.mt.md"), "---\ntest-id: MT-TEST-002\n---\n")

      files = @discoverer.find_tests(package: "my-package", base_dir: tmpdir)
      assert_equal 2, files.size, "Should find both test files"
    end
  end

  def test_find_tests_by_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-003-third.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "MT-TEST-001,MT-TEST-002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should find exactly two tests"
      assert files.any? { |f| f.include?("MT-TEST-001") }
      assert files.any? { |f| f.include?("MT-TEST-002") }
    end
  end

  def test_find_tests_by_partial_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-003-third.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001,002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should find two tests by partial IDs"
      assert files.any? { |f| f.include?("001") }
      assert files.any? { |f| f.include?("002") }
    end
  end

  def test_find_tests_comma_separated_with_spaces
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001, 002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should handle whitespace in comma-separated IDs"
    end
  end

  def test_find_tests_comma_separated_deduplicates
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001,MT-TEST-001",
        base_dir: tmpdir
      )
      assert_equal 1, files.size, "Should deduplicate overlapping ID matches"
    end
  end
end
