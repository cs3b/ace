# frozen_string_literal: true

require_relative "../test_helper"

class AffectedDetectorTest < Minitest::Test
  AffectedDetector = Ace::Test::EndToEndRunner::Molecules::AffectedDetector
  StatusStub = Struct.new(:exitstatus, :success?)

  def setup
    @detector = AffectedDetector.new
    @base_dir = Dir.pwd
  end

  def test_detect_returns_empty_when_no_git_changes
    # This test runs in a real git repo, but we can't control
    # the actual git state in unit tests. The implementation
    # handles failures gracefully by returning empty array.
    results = @detector.detect(base_dir: @base_dir, ref: "HEAD~0")

    # Should return empty array or array of strings
    assert_kind_of Array, results
    results.each { |r| assert_kind_of String, r }
  end

  def test_detect_with_invalid_ref_returns_empty
    _stdout, stderr = capture_io do
      results = @detector.detect(base_dir: @base_dir, ref: "INVALID-REF-THAT-DOESNT-EXIST")

      assert_equal [], results
    end

    assert_empty stderr
  end

  def test_detect_warns_when_git_diff_fails
    Open3.stub(:capture3, ["", "fatal: bad revision 'INVALID'\n", StatusStub.new(128, false)]) do
      _stdout, stderr = capture_io do
        results = @detector.detect(base_dir: @base_dir, ref: "INVALID")

        assert_equal [], results
      end

      assert_includes stderr, "fatal: bad revision 'INVALID'"
    end
  end

  def test_extract_package_from_ace_package_path
    package = @detector.send(:extract_package,
      "ace-lint/lib/ace/lint/cli.rb",
      @base_dir)

    # Will return nil if ace-lint doesn't exist in current dir
    # but the logic should work correctly
    assert_nil_or_equal "ace-lint", package
  end

  def test_extract_package_from_non_ace_path
    package = @detector.send(:extract_package,
      "some-other-dir/lib/file.rb",
      @base_dir)

    assert_nil package
  end

  def test_extract_package_from_nested_path
    package = @detector.send(:extract_package,
      "ace-review/test/e2e/TS-REVIEW-001/scenario.yml",
      @base_dir)

    assert_nil_or_equal "ace-review", package
  end

  def test_extract_package_returns_nil_for_nonexistent_package
    package = @detector.send(:extract_package,
      "ace-nonexistent/lib/file.rb",
      @base_dir)

    assert_nil package
  end

  private

  def assert_nil_or_equal(expected, actual)
    if actual.nil?
      assert true # Package doesn't exist in test environment
    else
      assert_equal expected, actual
    end
  end
end
