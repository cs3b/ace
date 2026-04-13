# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/git/worktree/models/worktree_metadata"

module Ace
  module Git
    module Worktree
      module Models
        class WorktreeMetadataTest < Minitest::Test
          # Test initialization with all attributes
          def test_initialize_with_all_attributes
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081",
              target_branch: "080-parent-branch",
              created_at: Time.now,
              updated_at: Time.now
            )

            assert_equal "081-fix-auth", metadata.branch
            assert_equal ".ace-wt/task.081", metadata.path
            assert_equal "080-parent-branch", metadata.target_branch
          end

          # Test initialization without target_branch
          def test_initialize_without_target_branch
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081"
            )

            assert_equal "081-fix-auth", metadata.branch
            assert_equal ".ace-wt/task.081", metadata.path
            assert_nil metadata.target_branch
          end

          # Test serialization with target_branch
          def test_to_h_includes_target_branch
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081",
              target_branch: "080-parent-branch"
            )

            hash = metadata.to_h

            assert_equal "081-fix-auth", hash["branch"]
            assert_equal ".ace-wt/task.081", hash["path"]
            assert_equal "080-parent-branch", hash["target_branch"]
          end

          # Test serialization without target_branch
          def test_to_h_excludes_nil_target_branch
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081"
            )

            hash = metadata.to_h

            assert_equal "081-fix-auth", hash["branch"]
            assert_equal ".ace-wt/task.081", hash["path"]
            refute hash.key?("target_branch"), "target_branch should not be in hash when nil"
          end

          # Test deserialization from task data with target_branch
          def test_from_task_data_with_target_branch
            task_data = {
              "worktree" => {
                "branch" => "081-fix-auth",
                "path" => ".ace-wt/task.081",
                "target_branch" => "080-parent-branch",
                "created_at" => "2025-11-04 13:45:00"
              }
            }

            metadata = WorktreeMetadata.from_task_data(task_data)

            assert_equal "081-fix-auth", metadata.branch
            assert_equal ".ace-wt/task.081", metadata.path
            assert_equal "080-parent-branch", metadata.target_branch
          end

          # Test deserialization from task data without target_branch
          def test_from_task_data_without_target_branch
            task_data = {
              "worktree" => {
                "branch" => "081-fix-auth",
                "path" => ".ace-wt/task.081",
                "created_at" => "2025-11-04 13:45:00"
              }
            }

            metadata = WorktreeMetadata.from_task_data(task_data)

            assert_equal "081-fix-auth", metadata.branch
            assert_equal ".ace-wt/task.081", metadata.path
            assert_nil metadata.target_branch
          end

          # Test deserialization returns nil when worktree is missing
          def test_from_task_data_returns_nil_without_worktree
            task_data = {
              "branch" => "081-fix-auth"
            }

            metadata = WorktreeMetadata.from_task_data(task_data)

            assert_nil metadata
          end

          # Test update preserves target_branch
          def test_update_preserves_target_branch
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081",
              target_branch: "080-parent-branch"
            )

            updated = metadata.update(branch: "082-new-branch")

            assert_equal "082-new-branch", updated.branch
            assert_equal ".ace-wt/task.081", updated.path
            assert_equal "080-parent-branch", updated.target_branch, "target_branch should be preserved"
          end

          # Test update preserves nil target_branch
          def test_update_preserves_nil_target_branch
            metadata = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081"
            )

            updated = metadata.update(branch: "082-new-branch")

            assert_equal "082-new-branch", updated.branch
            assert_equal ".ace-wt/task.081", updated.path
            assert_nil updated.target_branch
          end

          # Test YAML roundtrip with target_branch
          def test_yaml_roundtrip_with_target_branch
            original = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081",
              target_branch: "080-parent-branch"
            )

            yaml_string = original.to_yaml
            parsed = YAML.safe_load(yaml_string, permitted_classes: [Time])

            assert_equal "081-fix-auth", parsed["branch"]
            assert_equal ".ace-wt/task.081", parsed["path"]
            assert_equal "080-parent-branch", parsed["target_branch"]
          end

          # Test YAML roundtrip without target_branch
          def test_yaml_roundtrip_without_target_branch
            original = WorktreeMetadata.new(
              branch: "081-fix-auth",
              path: ".ace-wt/task.081"
            )

            yaml_string = original.to_yaml
            parsed = YAML.safe_load(yaml_string, permitted_classes: [Time])

            assert_equal "081-fix-auth", parsed["branch"]
            assert_equal ".ace-wt/task.081", parsed["path"]
            refute parsed.key?("target_branch"), "target_branch should not be in YAML when nil"
          end
        end
      end
    end
  end
end
