# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/string_normalizer"

class StringNormalizerTest < Minitest::Test
  def test_normalize_for_filename_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_for_filename("Hello World!")
    assert_equal "hello-world", result
  end

  def test_normalize_for_filename_with_special_chars
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_for_filename("Test@#$%File")
    assert_equal "test-file", result
  end

  def test_normalize_for_filename_removes_multiple_dashes
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_for_filename("test---file")
    assert_equal "test-file", result
  end

  def test_normalize_for_filename_with_nil
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_for_filename(nil)
    assert_equal "", result
  end

  def test_slugify_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.slugify("Hello World")
    assert_equal "hello-world", result
  end

  def test_slugify_with_custom_separator
    result = Ace::Taskflow::Molecules::StringNormalizer.slugify("Hello World", separator: '_')
    assert_equal "hello_world", result
  end

  def test_slugify_preserves_numbers
    result = Ace::Taskflow::Molecules::StringNormalizer.slugify("Task 123")
    assert_equal "task-123", result
  end

  def test_titleize_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.titleize("hello world")
    assert_equal "Hello World", result
  end

  def test_titleize_with_underscores
    result = Ace::Taskflow::Molecules::StringNormalizer.titleize("hello_world_test")
    assert_equal "Hello World Test", result
  end

  def test_titleize_with_dashes
    result = Ace::Taskflow::Molecules::StringNormalizer.titleize("hello-world-test")
    assert_equal "Hello World Test", result
  end

  def test_truncate_short_string
    result = Ace::Taskflow::Molecules::StringNormalizer.truncate("Short", length: 10)
    assert_equal "Short", result
  end

  def test_truncate_long_string
    result = Ace::Taskflow::Molecules::StringNormalizer.truncate("This is a long string", length: 10)
    assert_equal "This is...", result
  end

  def test_truncate_with_custom_ellipsis
    result = Ace::Taskflow::Molecules::StringNormalizer.truncate("Long string", length: 8, ellipsis: '…')
    assert_equal "Long st…", result
  end

  def test_truncate_with_nil
    result = Ace::Taskflow::Molecules::StringNormalizer.truncate(nil, length: 10)
    assert_equal "", result
  end

  def test_extract_initials_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.extract_initials("Hello World")
    assert_equal "HW", result
  end

  def test_extract_initials_with_max_limit
    result = Ace::Taskflow::Molecules::StringNormalizer.extract_initials("One Two Three Four", max_initials: 2)
    assert_equal "OT", result
  end

  def test_extract_initials_with_underscores
    result = Ace::Taskflow::Molecules::StringNormalizer.extract_initials("first_second_third")
    assert_equal "FST", result
  end

  def test_normalize_whitespace
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_whitespace("Hello    World  \n  Test")
    assert_equal "Hello World Test", result
  end

  def test_normalize_whitespace_with_nil
    result = Ace::Taskflow::Molecules::StringNormalizer.normalize_whitespace(nil)
    assert_equal "", result
  end

  def test_remove_special_chars_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.remove_special_chars("Hello@World!")
    assert_equal "HelloWorld", result
  end

  def test_remove_special_chars_with_keep
    result = Ace::Taskflow::Molecules::StringNormalizer.remove_special_chars("test@example.com", keep: '@.')
    assert_equal "test@example.com", result
  end

  def test_to_snake_case_from_camel
    result = Ace::Taskflow::Molecules::StringNormalizer.to_snake_case("HelloWorld")
    assert_equal "hello_world", result
  end

  def test_to_snake_case_from_spaces
    result = Ace::Taskflow::Molecules::StringNormalizer.to_snake_case("Hello World Test")
    assert_equal "hello_world_test", result
  end

  def test_to_snake_case_from_dashes
    result = Ace::Taskflow::Molecules::StringNormalizer.to_snake_case("hello-world-test")
    assert_equal "hello_world_test", result
  end

  def test_to_camel_case_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.to_camel_case("hello_world")
    assert_equal "helloWorld", result
  end

  def test_to_camel_case_with_first_upper
    result = Ace::Taskflow::Molecules::StringNormalizer.to_camel_case("hello_world", first_upper: true)
    assert_equal "HelloWorld", result
  end

  def test_to_camel_case_with_spaces
    result = Ace::Taskflow::Molecules::StringNormalizer.to_camel_case("hello world test")
    assert_equal "helloWorldTest", result
  end

  def test_wrap_text_basic
    result = Ace::Taskflow::Molecules::StringNormalizer.wrap_text("This is a test", width: 10)
    assert_equal "This is a\ntest", result
  end

  def test_wrap_text_exact_width
    result = Ace::Taskflow::Molecules::StringNormalizer.wrap_text("Hello World", width: 11)
    assert_equal "Hello World", result
  end

  def test_wrap_text_single_long_word
    result = Ace::Taskflow::Molecules::StringNormalizer.wrap_text("VeryLongWord", width: 5)
    assert_equal "VeryLongWord", result
  end

  def test_wrap_text_with_nil
    result = Ace::Taskflow::Molecules::StringNormalizer.wrap_text(nil, width: 10)
    assert_equal "", result
  end
end
