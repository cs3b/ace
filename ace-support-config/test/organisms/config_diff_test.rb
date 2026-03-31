# frozen_string_literal: true

require "test_helper"
require "ace/support/config/organisms/config_diff"

module Ace
  module Support
    module Config
      module Organisms
        class ConfigDiffTest < TestCase
          def test_local_flag_prefers_project_config_directory
            differ = ConfigDiff.new(global: true, local: true)

            assert_equal ".ace", differ.send(:config_directory)
          end

          def test_one_line_summary_includes_same_when_verbose
            differ = ConfigDiff.new(one_line: true, verbose: true)
            differ.instance_variable_set(:@diffs, [{status: :same, file: ".ace/demo.yml"}])

            output, = capture_io do
              differ.send(:print_one_line_summary)
            end

            assert_includes output, "SAME:    .ace/demo.yml"
          end
        end
      end
    end
  end
end
