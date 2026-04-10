# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/atoms/test_type_detector"

module Ace
  module TestRunner
    module Atoms
      class TestTypeDetectorTest < Minitest::Test
        def test_needs_subprocess_for_unit_directory_file_when_content_uses_open3
          Dir.mktmpdir do |tmpdir|
            file_path = File.join(tmpdir, "test", "molecules", "example_test.rb")
            FileUtils.mkdir_p(File.dirname(file_path))
            File.write(file_path, <<~RUBY)
              require "open3"

              class ExampleTest < Minitest::Test
                def test_runs_command
                  Open3.capture3("echo", "hi")
                end
              end
            RUBY

            detector = Ace::TestRunner::Atoms::TestTypeDetector.new

            assert detector.needs_subprocess?(file_path)
            assert_equal :subprocess_required, detector.test_type(file_path)
          end
        end

        def test_keeps_plain_unit_directory_file_in_process
          Dir.mktmpdir do |tmpdir|
            file_path = File.join(tmpdir, "test", "organisms", "example_test.rb")
            FileUtils.mkdir_p(File.dirname(file_path))
            File.write(file_path, <<~RUBY)
              class ExampleTest < Minitest::Test
                def test_truth
                  assert true
                end
              end
            RUBY

            detector = Ace::TestRunner::Atoms::TestTypeDetector.new

            refute detector.needs_subprocess?(file_path)
            assert_equal :unit, detector.test_type(file_path)
          end
        end
      end
    end
  end
end
