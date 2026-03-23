# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Models
        class ConfigGroupTest < TestCase
          def test_initializes_with_files
            group = ConfigGroup.new(
              name: "taskflow",
              source: ".ace-taskflow/.ace/git/commit.yml",
              config: {"model" => "gflash"},
              files: ["a.txt", "b.txt"]
            )

            assert_equal "taskflow", group.name
            assert_equal ".ace-taskflow/.ace/git/commit.yml", group.source
            assert_equal({"model" => "gflash"}, group.config)
            assert_equal ["a.txt", "b.txt"], group.files
          end

          def test_add_file_returns_new_group
            group = ConfigGroup.new(
              name: "default",
              source: ".ace/git/commit.yml",
              config: {"model" => "glite"},
              files: ["a.txt"]
            )

            updated = group.add_file("b.txt")

            assert_equal ["a.txt"], group.files
            assert_equal ["a.txt", "b.txt"], updated.files
          end
        end
      end
    end
  end
end
