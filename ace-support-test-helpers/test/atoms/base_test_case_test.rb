# frozen_string_literal: true

require "test_helper"

class BaseTestCaseTest < Minitest::Test
  def test_base_test_case_includes_test_helper
    test_case = Ace::TestSupport::BaseTestCase.new("test")

    # Verify TestHelper methods are available
    assert test_case.respond_to?(:with_temp_dir)
    assert test_case.respond_to?(:with_temp_file)
    assert test_case.respond_to?(:assert_file_exists)
    assert test_case.respond_to?(:assert_file_content)
    assert test_case.respond_to?(:assert_directory_exists)
    assert test_case.respond_to?(:capture_subprocess_io)
  end

  def test_fixture_path_generates_correct_path
    # Create a mock test case to test fixture_path
    test_case = Class.new(Ace::TestSupport::BaseTestCase) do
      def test_fixture_usage
        # This should generate a path relative to this test file
        fixture_path("data.yml")
      end
    end.new("test_fixture_usage")

    path = test_case.test_fixture_usage
    assert path.end_with?("fixtures/data.yml"), "Should append fixtures/ to path"
  end

  def test_setup_stores_original_pwd
    original_pwd = Dir.pwd
    test_case = Ace::TestSupport::BaseTestCase.new("test")

    # Ensure we're in a valid directory
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      # Manually call setup
      test_case.setup

      # The instance variable should be set
      assert_equal File.realpath(dir), File.realpath(test_case.instance_variable_get(:@original_pwd))
    end
  ensure
    Dir.chdir(original_pwd) if Dir.exist?(original_pwd)
  end

  def test_teardown_restores_original_pwd
    test_case = Ace::TestSupport::BaseTestCase.new("test")
    original_pwd = Dir.pwd

    Dir.mktmpdir do |temp_dir|
      # Setup and change directory
      test_case.setup
      Dir.chdir(temp_dir)
      assert_equal File.realpath(temp_dir), File.realpath(Dir.pwd)

      # Teardown should restore
      test_case.teardown
      assert_equal File.realpath(original_pwd), File.realpath(Dir.pwd)
    end
  end

  def test_ace_test_case_alias_works
    # Test that AceTestCase is an alias for BaseTestCase
    assert_equal Ace::TestSupport::BaseTestCase, Ace::TestSupport::AceTestCase
    assert_equal Ace::TestSupport::BaseTestCase, ::AceTestCase
  end

  def test_base_test_case_inherits_from_minitest
    assert Ace::TestSupport::BaseTestCase < Minitest::Test
  end

  # Integration test showing how a derived test would work
  def test_derived_test_case_functionality
    original_dir = Dir.pwd

    test_class = Class.new(Ace::TestSupport::BaseTestCase) do
      def test_temp_dir_helper
        with_temp_dir do |dir|
          File.write("test.txt", "content")
          assert_file_exists("test.txt")
          assert_file_content("test.txt", "content")
        end
      end
    end

    test_instance = test_class.new("test_temp_dir_helper")

    # Run the test manually
    test_instance.setup
    test_instance.test_temp_dir_helper
    test_instance.teardown

    # If we get here without exceptions, the test passed
    assert true, "Derived test case should work with helpers"
  ensure
    Dir.chdir(original_dir) if Dir.exist?(original_dir)
  end
end
