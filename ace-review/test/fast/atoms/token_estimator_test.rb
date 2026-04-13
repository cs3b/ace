# frozen_string_literal: true

require "test_helper"

class TokenEstimatorTest < AceReviewTest
  def setup
    super
    @estimator = Ace::Review::Atoms::TokenEstimator
  end

  # Basic estimation tests
  def test_estimate_simple_text
    result = @estimator.estimate("hello world")

    # "hello world" is 11 chars, 11/4 = 2.75, ceil = 3
    assert_equal 3, result
  end

  def test_estimate_uses_chars_divided_by_four
    # 8 chars = exactly 2 tokens
    result = @estimator.estimate("12345678")

    assert_equal 2, result
  end

  def test_estimate_rounds_up
    # 5 chars = 1.25 tokens, should round up to 2
    result = @estimator.estimate("hello")

    assert_equal 2, result
  end

  def test_estimate_single_char
    # 1 char = 0.25 tokens, should round up to 1
    result = @estimator.estimate("a")

    assert_equal 1, result
  end

  def test_estimate_longer_text
    # 100 chars = 25 tokens
    text = "a" * 100
    result = @estimator.estimate(text)

    assert_equal 25, result
  end

  # Edge cases
  def test_estimate_nil_returns_zero
    result = @estimator.estimate(nil)

    assert_equal 0, result
  end

  def test_estimate_empty_string_returns_zero
    result = @estimator.estimate("")

    assert_equal 0, result
  end

  # Accuracy test - within 20% of expected
  def test_estimate_accuracy_for_typical_code
    # Typical Ruby code sample
    code = <<~RUBY
      def calculate_sum(numbers)
        numbers.reduce(0) { |sum, n| sum + n }
      end

      result = calculate_sum([1, 2, 3, 4, 5])
      puts "Sum: \#{result}"
    RUBY

    result = @estimator.estimate(code)

    # Verify the heuristic math: chars/4 rounded up
    expected = (code.length.to_f / 4).ceil
    assert result > 0
    assert_equal expected, result
  end

  # File estimation tests
  def test_estimate_file
    # Create a test file
    test_file = File.join(@test_dir, "test_code.rb")
    content = "def hello; puts 'world'; end"
    File.write(test_file, content)

    result = @estimator.estimate_file(test_file)

    expected = (content.length.to_f / 4).ceil
    assert_equal expected, result
  end

  def test_estimate_file_with_multiline
    test_file = File.join(@test_dir, "test_multi.rb")
    content = <<~RUBY
      class Example
        def initialize
          @value = 0
        end

        def increment
          @value += 1
        end
      end
    RUBY
    File.write(test_file, content)

    result = @estimator.estimate_file(test_file)

    expected = (content.length.to_f / 4).ceil
    assert_equal expected, result
  end

  def test_estimate_file_not_found
    assert_raises(Errno::ENOENT) do
      @estimator.estimate_file("/nonexistent/file.rb")
    end
  end

  def test_estimate_file_empty
    test_file = File.join(@test_dir, "empty.txt")
    File.write(test_file, "")

    result = @estimator.estimate_file(test_file)

    assert_equal 0, result
  end

  # Batch estimation tests
  def test_estimate_many
    texts = ["hello", "world", "test"]
    result = @estimator.estimate_many(texts)

    # "hello" = 5/4 = 2, "world" = 5/4 = 2, "test" = 4/4 = 1
    # Total = 5
    assert_equal 5, result
  end

  def test_estimate_many_nil_returns_zero
    result = @estimator.estimate_many(nil)

    assert_equal 0, result
  end

  def test_estimate_many_empty_array_returns_zero
    result = @estimator.estimate_many([])

    assert_equal 0, result
  end

  def test_estimate_many_with_nil_elements
    texts = ["hello", nil, "world"]
    result = @estimator.estimate_many(texts)

    # nil contributes 0
    assert_equal 4, result
  end

  # File batch estimation tests
  def test_estimate_files
    file1 = File.join(@test_dir, "file1.rb")
    file2 = File.join(@test_dir, "file2.rb")
    File.write(file1, "hello")  # 5/4 = 2
    File.write(file2, "world")  # 5/4 = 2

    result = @estimator.estimate_files([file1, file2])

    assert_equal 4, result
  end

  def test_estimate_files_nil_returns_zero
    result = @estimator.estimate_files(nil)

    assert_equal 0, result
  end

  def test_estimate_files_empty_array_returns_zero
    result = @estimator.estimate_files([])

    assert_equal 0, result
  end

  def test_estimate_files_with_nonexistent_file
    file1 = File.join(@test_dir, "existing.rb")
    File.write(file1, "hello")

    assert_raises(Errno::ENOENT) do
      @estimator.estimate_files([file1, "/nonexistent/file.rb"])
    end
  end

  # Constant accessibility
  def test_chars_per_token_constant
    assert_equal 4, Ace::Review::Atoms::TokenEstimator::CHARS_PER_TOKEN
  end
end
