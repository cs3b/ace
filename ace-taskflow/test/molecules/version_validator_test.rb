# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/version_validator"

class VersionValidatorTest < Minitest::Test
  def test_valid_format_with_valid_version
    assert Ace::Taskflow::Molecules::VersionValidator.valid_format?("v.0.9.0")
    assert Ace::Taskflow::Molecules::VersionValidator.valid_format?("v.1.0.0")
    assert Ace::Taskflow::Molecules::VersionValidator.valid_format?("v.10.25.3")
  end

  def test_valid_format_with_invalid_version
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?("0.9.0")
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?("v.0.9")
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?("v0.9.0")
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?("v.0.9.0-feature")
  end

  def test_valid_format_with_nil_or_empty
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?(nil)
    refute Ace::Taskflow::Molecules::VersionValidator.valid_format?("")
  end

  def test_extract_version_from_simple_version
    result = Ace::Taskflow::Molecules::VersionValidator.extract_version("v.0.9.0")
    assert_equal "v.0.9.0", result
  end

  def test_extract_version_from_release_name_with_codename
    result = Ace::Taskflow::Molecules::VersionValidator.extract_version("v.0.9.0-feature-name")
    assert_equal "v.0.9.0", result
  end

  def test_extract_version_from_invalid_name
    result = Ace::Taskflow::Molecules::VersionValidator.extract_version("feature-name")
    assert_nil result
  end

  def test_extract_version_with_nil_or_empty
    assert_nil Ace::Taskflow::Molecules::VersionValidator.extract_version(nil)
    assert_nil Ace::Taskflow::Molecules::VersionValidator.extract_version("")
  end

  def test_version_to_array
    result = Ace::Taskflow::Molecules::VersionValidator.version_to_array("v.0.9.0")
    assert_equal [0, 9, 0], result
  end

  def test_version_to_array_with_double_digits
    result = Ace::Taskflow::Molecules::VersionValidator.version_to_array("v.1.10.25")
    assert_equal [1, 10, 25], result
  end

  def test_version_to_array_with_nil_or_empty
    assert_equal [], Ace::Taskflow::Molecules::VersionValidator.version_to_array(nil)
    assert_equal [], Ace::Taskflow::Molecules::VersionValidator.version_to_array("")
  end

  def test_increment_minor_version
    result = Ace::Taskflow::Molecules::VersionValidator.increment_minor("v.0.9.0")
    assert_equal "v.0.10.0", result
  end

  def test_increment_minor_resets_patch
    result = Ace::Taskflow::Molecules::VersionValidator.increment_minor("v.0.9.5")
    assert_equal "v.0.10.0", result
  end

  def test_increment_minor_with_invalid_version
    result = Ace::Taskflow::Molecules::VersionValidator.increment_minor("invalid")
    assert_nil result
  end

  def test_increment_major_version
    result = Ace::Taskflow::Molecules::VersionValidator.increment_major("v.0.9.0")
    assert_equal "v.1.0.0", result
  end

  def test_increment_major_resets_minor_and_patch
    result = Ace::Taskflow::Molecules::VersionValidator.increment_major("v.0.9.5")
    assert_equal "v.1.0.0", result
  end

  def test_increment_patch_version
    result = Ace::Taskflow::Molecules::VersionValidator.increment_patch("v.0.9.0")
    assert_equal "v.0.9.1", result
  end

  def test_increment_patch_preserves_major_and_minor
    result = Ace::Taskflow::Molecules::VersionValidator.increment_patch("v.1.10.5")
    assert_equal "v.1.10.6", result
  end

  def test_compare_versions_equal
    result = Ace::Taskflow::Molecules::VersionValidator.compare("v.0.9.0", "v.0.9.0")
    assert_equal 0, result
  end

  def test_compare_versions_less_than
    result = Ace::Taskflow::Molecules::VersionValidator.compare("v.0.8.0", "v.0.9.0")
    assert_equal(-1, result)
  end

  def test_compare_versions_greater_than
    result = Ace::Taskflow::Molecules::VersionValidator.compare("v.0.10.0", "v.0.9.0")
    assert_equal 1, result
  end

  def test_compare_versions_with_invalid_returns_nil
    result = Ace::Taskflow::Molecules::VersionValidator.compare("v.0.9.0", "invalid")
    assert_nil result
  end

  def test_greater_than_returns_true
    result = Ace::Taskflow::Molecules::VersionValidator.greater_than?("v.0.10.0", "v.0.9.0")
    assert_equal true, result
  end

  def test_greater_than_returns_false
    result = Ace::Taskflow::Molecules::VersionValidator.greater_than?("v.0.8.0", "v.0.9.0")
    assert_equal false, result
  end

  def test_greater_than_with_equal_returns_false
    result = Ace::Taskflow::Molecules::VersionValidator.greater_than?("v.0.9.0", "v.0.9.0")
    assert_equal false, result
  end

  def test_less_than_returns_true
    result = Ace::Taskflow::Molecules::VersionValidator.less_than?("v.0.8.0", "v.0.9.0")
    assert_equal true, result
  end

  def test_less_than_returns_false
    result = Ace::Taskflow::Molecules::VersionValidator.less_than?("v.0.10.0", "v.0.9.0")
    assert_equal false, result
  end

  def test_build_release_name_with_codename
    result = Ace::Taskflow::Molecules::VersionValidator.build_release_name("v.0.10.0", "feature-name")
    assert_equal "v.0.10.0-feature-name", result
  end

  def test_build_release_name_normalizes_codename
    result = Ace::Taskflow::Molecules::VersionValidator.build_release_name("v.0.10.0", "Feature Name!")
    assert_equal "v.0.10.0-feature-name", result
  end

  def test_build_release_name_without_codename
    result = Ace::Taskflow::Molecules::VersionValidator.build_release_name("v.0.10.0", "")
    assert_equal "v.0.10.0", result
  end

  def test_build_release_name_with_nil_codename
    result = Ace::Taskflow::Molecules::VersionValidator.build_release_name("v.0.10.0", nil)
    assert_equal "v.0.10.0", result
  end

  def test_build_release_name_removes_leading_trailing_dashes
    result = Ace::Taskflow::Molecules::VersionValidator.build_release_name("v.0.10.0", "--feature--")
    assert_equal "v.0.10.0-feature", result
  end
end
