# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Detects test folder location from test file paths and calculates report directory
      module TestFolderDetector
        module_function

        # Given test file paths, find the test folder and calculate report directory
        # Returns the parent directory of the test folder + "/test-reports"
        #
        # Example:
        #   files = ["ace-taskflow/test/commands/tasks_command_test.rb"]
        #   detect_report_dir(files) # => "ace-taskflow/test-reports"
        def detect_report_dir(test_files)
          return nil if test_files.nil? || test_files.empty?

          # Get the first test file and find its test folder
          first_file = test_files.first
          test_folder = find_test_folder(first_file)

          return nil unless test_folder

          # Get parent directory and append test-reports
          parent_dir = File.dirname(test_folder)
          File.join(parent_dir, "test-reports")
        end

        # Find the test folder in a given file path
        # Looks for "/test/" in the path and returns the path up to and including "test"
        #
        # Example:
        #   find_test_folder("ace-taskflow/test/commands/tasks_command_test.rb")
        #   # => "ace-taskflow/test"
        def find_test_folder(file_path)
          # Remove line number suffix if present (file:line format)
          file_path = file_path.sub(/:\d+$/, '')

          # Split path into parts
          parts = file_path.split('/')

          # Find index of "test" directory
          test_index = parts.index('test')
          return nil unless test_index

          # Return path up to and including test directory
          parts[0..test_index].join('/')
        end
      end
    end
  end
end
