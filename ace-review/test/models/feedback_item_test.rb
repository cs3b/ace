# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Models
      class FeedbackItemTest < AceReviewTest
        def setup
          super
          @valid_attrs = {
            id: "8o7abc",
            title: "Missing error handling",
            files: ["src/handlers/user.rb:42-55"],
            reviewer: "google:gemini-2.5-flash",
            status: "pending",
            priority: "high",
            finding: "The error handling is incomplete"
          }
        end

        # Initialization tests

        def test_initialization_with_all_attributes
          item = FeedbackItem.new(@valid_attrs)

          assert_equal "8o7abc", item.id
          assert_equal "Missing error handling", item.title
          assert_equal ["src/handlers/user.rb:42-55"], item.files
          assert_equal "google:gemini-2.5-flash", item.reviewer
          assert_equal "pending", item.status
          assert_equal "high", item.priority
          assert_equal "The error handling is incomplete", item.finding
        end

        def test_initialization_with_string_keys
          string_attrs = {
            "id" => "8o7abc",
            "title" => "Missing error handling",
            "files" => ["src/handlers/user.rb:42-55"],
            "reviewer" => "google:gemini-2.5-flash",
            "status" => "pending",
            "priority" => "high",
            "finding" => "The error handling is incomplete"
          }
          item = FeedbackItem.new(string_attrs)

          assert_equal "8o7abc", item.id
          assert_equal "Missing error handling", item.title
        end

        def test_initialization_with_default_status
          attrs = @valid_attrs.except(:status)
          item = FeedbackItem.new(attrs)

          assert_equal "draft", item.status
        end

        def test_initialization_with_default_priority
          attrs = @valid_attrs.except(:priority)
          item = FeedbackItem.new(attrs)

          assert_equal "medium", item.priority
        end

        def test_initialization_sets_created_timestamp
          item = FeedbackItem.new(@valid_attrs)

          refute_nil item.created
          # Verify it's a valid ISO8601 timestamp
          Time.iso8601(item.created)
        end

        def test_initialization_sets_updated_to_created
          item = FeedbackItem.new(@valid_attrs)

          assert_equal item.created, item.updated
        end

        def test_initialization_with_optional_attributes
          attrs = @valid_attrs.merge(
            context: "Additional context here",
            research: "Verification notes",
            resolution: "Fixed by adding try-catch"
          )
          item = FeedbackItem.new(attrs)

          assert_equal "Additional context here", item.context
          assert_equal "Verification notes", item.research
          assert_equal "Fixed by adding try-catch", item.resolution
        end

        def test_initialization_normalizes_files_to_array
          attrs = @valid_attrs.merge(files: "src/single_file.rb:10")
          item = FeedbackItem.new(attrs)

          assert_instance_of Array, item.files
          assert_equal ["src/single_file.rb:10"], item.files
        end

        def test_initialization_handles_nil_files
          attrs = @valid_attrs.merge(files: nil)
          item = FeedbackItem.new(attrs)

          assert_instance_of Array, item.files
          assert_empty item.files
        end

        # Validation tests

        def test_validates_status_values
          FeedbackItem::VALID_STATUSES.each do |status|
            attrs = @valid_attrs.merge(status: status)
            item = FeedbackItem.new(attrs)
            assert_equal status, item.status
          end
        end

        def test_raises_on_invalid_status
          attrs = @valid_attrs.merge(status: "invalid_status")

          error = assert_raises(ArgumentError) { FeedbackItem.new(attrs) }
          assert_includes error.message, "Invalid status 'invalid_status'"
          assert_includes error.message, "draft, pending, invalid, skip, done"
        end

        def test_validates_priority_values
          FeedbackItem::VALID_PRIORITIES.each do |priority|
            attrs = @valid_attrs.merge(priority: priority)
            item = FeedbackItem.new(attrs)
            assert_equal priority, item.priority
          end
        end

        def test_raises_on_invalid_priority
          attrs = @valid_attrs.merge(priority: "invalid_priority")

          error = assert_raises(ArgumentError) { FeedbackItem.new(attrs) }
          assert_includes error.message, "Invalid priority 'invalid_priority'"
          assert_includes error.message, "critical, high, medium, low"
        end

        # Immutability tests

        def test_files_array_is_frozen
          item = FeedbackItem.new(@valid_attrs)

          assert_raises(FrozenError) { item.files << "new_file.rb" }
        end

        def test_no_setter_methods
          item = FeedbackItem.new(@valid_attrs)

          refute_respond_to item, :status=
          refute_respond_to item, :priority=
          refute_respond_to item, :title=
        end

        # Serialization tests

        def test_to_h_returns_hash
          item = FeedbackItem.new(@valid_attrs)
          hash = item.to_h

          assert_instance_of Hash, hash
          assert_equal "8o7abc", hash["id"]
          assert_equal "Missing error handling", hash["title"]
          assert_equal ["src/handlers/user.rb:42-55"], hash["files"]
          assert_equal "google:gemini-2.5-flash", hash["reviewer"]
          assert_equal "pending", hash["status"]
          assert_equal "high", hash["priority"]
          assert_equal "The error handling is incomplete", hash["finding"]
        end

        def test_to_h_excludes_nil_values
          item = FeedbackItem.new(@valid_attrs)
          hash = item.to_h

          refute hash.key?("context")
          refute hash.key?("research")
          refute hash.key?("resolution")
        end

        def test_to_h_returns_string_keys
          item = FeedbackItem.new(@valid_attrs)
          hash = item.to_h

          assert hash.keys.all? { |k| k.is_a?(String) }
        end

        def test_to_h_returns_independent_files_array
          item = FeedbackItem.new(@valid_attrs)
          hash = item.to_h

          # Modifying returned array should not affect original
          hash["files"] << "new_file.rb"
          assert_equal ["src/handlers/user.rb:42-55"], item.files
        end

        def test_to_yaml_returns_valid_yaml
          item = FeedbackItem.new(@valid_attrs)
          yaml_str = item.to_yaml

          parsed = YAML.safe_load(yaml_str)
          assert_equal "8o7abc", parsed["id"]
          assert_equal "Missing error handling", parsed["title"]
        end

        # dup_with tests

        def test_dup_with_creates_new_instance
          item = FeedbackItem.new(@valid_attrs)
          new_item = item.dup_with(status: "done")

          refute_same item, new_item
          assert_equal "pending", item.status
          assert_equal "done", new_item.status
        end

        def test_dup_with_preserves_unchanged_attributes
          item = FeedbackItem.new(@valid_attrs)
          new_item = item.dup_with(status: "done")

          assert_equal item.id, new_item.id
          assert_equal item.title, new_item.title
          assert_equal item.files, new_item.files
          assert_equal item.priority, new_item.priority
        end

        def test_dup_with_updates_updated_timestamp
          # Create item with explicit timestamp
          attrs = @valid_attrs.merge(
            created: "2025-01-15T10:00:00Z",
            updated: "2025-01-15T10:00:00Z"
          )
          item = FeedbackItem.new(attrs)
          new_item = item.dup_with(status: "done")

          # The updated timestamp should be different (current time vs fixed time)
          refute_equal "2025-01-15T10:00:00Z", new_item.updated
        end

        def test_dup_with_preserves_created_timestamp
          item = FeedbackItem.new(@valid_attrs)
          new_item = item.dup_with(status: "done")

          assert_equal item.created, new_item.created
        end

        def test_dup_with_multiple_changes
          item = FeedbackItem.new(@valid_attrs)
          new_item = item.dup_with(
            status: "done",
            resolution: "Fixed the issue"
          )

          assert_equal "done", new_item.status
          assert_equal "Fixed the issue", new_item.resolution
        end

        def test_dup_with_validates_new_values
          item = FeedbackItem.new(@valid_attrs)

          # Use a truly invalid status (not one of draft, pending, invalid, skip, done)
          assert_raises(ArgumentError) { item.dup_with(status: "nonexistent_status") }
        end

        # Equality tests

        def test_equality_with_same_attributes
          item1 = FeedbackItem.new(@valid_attrs)
          item2 = FeedbackItem.new(@valid_attrs)

          assert_equal item1, item2
        end

        def test_inequality_with_different_status
          item1 = FeedbackItem.new(@valid_attrs)
          item2 = FeedbackItem.new(@valid_attrs.merge(status: "done"))

          refute_equal item1, item2
        end

        def test_inequality_with_non_feedback_item
          item = FeedbackItem.new(@valid_attrs)

          refute_equal item, "not a feedback item"
          refute_equal item, nil
        end

        def test_hash_consistency
          item1 = FeedbackItem.new(@valid_attrs)
          item2 = FeedbackItem.new(@valid_attrs)

          assert_equal item1.hash, item2.hash
        end

        def test_eql_alias
          item1 = FeedbackItem.new(@valid_attrs)
          item2 = FeedbackItem.new(@valid_attrs)

          assert item1.eql?(item2)
        end

        # Roundtrip tests

        def test_roundtrip_through_hash
          original = FeedbackItem.new(@valid_attrs.merge(
            context: "Some context",
            research: "Research notes"
          ))
          restored = FeedbackItem.new(original.to_h)

          assert_equal original.id, restored.id
          assert_equal original.title, restored.title
          assert_equal original.files, restored.files
          assert_equal original.status, restored.status
          assert_equal original.priority, restored.priority
          assert_equal original.context, restored.context
          assert_equal original.research, restored.research
        end

        def test_roundtrip_through_yaml
          original = FeedbackItem.new(@valid_attrs)
          yaml_str = original.to_yaml
          parsed = YAML.safe_load(yaml_str)
          restored = FeedbackItem.new(parsed)

          assert_equal original.id, restored.id
          assert_equal original.title, restored.title
          assert_equal original.status, restored.status
        end
      end
    end
  end
end
