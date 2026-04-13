# frozen_string_literal: true

require_relative "../test_helper"

class CorruptionPreventionTest < Minitest::Test
  include TestHelpers

  def setup
    @editor_class = Ace::Support::Markdown::Organisms::DocumentEditor
    @writer_class = Ace::Support::Markdown::Organisms::SafeFileWriter
  end

  def test_no_corruption_on_frontmatter_update
    # Simulate task 076/078 corruption scenario
    original_content = sample_markdown
    temp = create_temp_file(original_content)

    begin
      # Update frontmatter
      editor = @editor_class.new(temp.path)
      editor.update_frontmatter({"status" => "done", "updated_at" => "2025-10-18"})
      result = editor.save!(backup: true)

      assert result[:success], "Save should succeed"

      # Verify file is not corrupted
      saved_content = File.read(temp.path)
      refute_equal 3, saved_content.lines.count, "File should not be reduced to 3 lines (corruption)"

      # Verify frontmatter was updated
      assert_includes saved_content, "status: done"
      assert_includes saved_content, "updated_at: '2025-10-18'"

      # Verify body content preserved
      assert_includes saved_content, "# Test Document"
      assert_includes saved_content, "## Section 1"
      assert_includes saved_content, "## References"

      # Verify backup was created
      assert result[:backup_path], "Backup should be created"
      assert File.exist?(result[:backup_path]), "Backup file should exist"
    ensure
      temp.close
      temp.unlink
      # Cleanup backup
      Dir.glob("#{temp.path}.backup.*").each { |f| File.delete(f) }
    end
  end

  def test_rollback_on_validation_failure
    temp = create_temp_file(sample_markdown)

    begin
      editor = @editor_class.new(temp.path)

      # Make an invalid update (e.g., break the YAML)
      editor.update_frontmatter({"status" => "invalid-status-with-special-chars: : :"})

      # Try to save with validation
      rules = {
        enums: {"status" => ["pending", "in-progress", "done", "blocked"]}
      }

      result = editor.save!(validate_before: true, rules: rules)

      # Should fail validation
      refute result[:success], "Save should fail validation"
      assert result[:errors].any?, "Should have validation errors"

      # Original file should be unchanged
      saved_content = File.read(temp.path)
      assert_includes saved_content, "status: pending", "Original status should be preserved"
    ensure
      temp.close
      temp.unlink
    end
  end

  def test_atomic_write_prevents_partial_corruption
    temp = create_temp_file(sample_markdown)

    begin
      # Simulate a write that would fail midway
      # The atomic write (temp file + move) should prevent partial writes

      new_content = "---\nid: test\nstatus: done\n---\n\nNew content"

      result = @writer_class.write(temp.path, new_content, backup: true)

      assert result[:success]

      # Verify complete content was written (not partial)
      saved_content = File.read(temp.path)
      assert_equal new_content, saved_content

      # Verify backup exists
      assert result[:backup_path]
      assert File.exist?(result[:backup_path])

      # Verify backup contains original content
      backup_content = File.read(result[:backup_path])
      assert_includes backup_content, "id: test.001"
    ensure
      temp.close
      temp.unlink
      Dir.glob("#{temp.path}.backup.*").each { |f| File.delete(f) }
    end
  end

  def test_backup_and_rollback_workflow
    temp = create_temp_file(sample_markdown)

    begin
      editor = @editor_class.new(temp.path)

      # Make changes
      editor.update_frontmatter({"status" => "in-progress"})
      save_result = editor.save!(backup: true)

      assert save_result[:success]
      assert save_result[:backup_path]

      # Verify change was saved
      assert_includes File.read(temp.path), "status: in-progress"

      # Rollback
      rollback_result = editor.rollback

      assert rollback_result[:success], "Rollback should succeed"

      # Verify original content restored
      restored_content = File.read(temp.path)
      assert_includes restored_content, "status: pending"
      refute_includes restored_content, "status: in-progress"
    ensure
      temp.close
      temp.unlink
    end
  end

  def test_section_update_preserves_entire_document
    temp = create_temp_file(sample_markdown)

    begin
      editor = @editor_class.new(temp.path)

      # Update a section
      editor.replace_section("References", "- New Reference 1\n- New Reference 2\n- New Reference 3")
      result = editor.save!(backup: true)

      assert result[:success]

      saved_content = File.read(temp.path)

      # Verify frontmatter preserved
      assert_includes saved_content, "id: test.001"
      assert_includes saved_content, "status: pending"

      # Verify other sections preserved
      assert_includes saved_content, "# Test Document"
      assert_includes saved_content, "## Section 1"
      assert_includes saved_content, "Content of section 1"

      # Verify updated section
      assert_includes saved_content, "New Reference 1"
      assert_includes saved_content, "New Reference 3"
    ensure
      temp.close
      temp.unlink
      Dir.glob("#{temp.path}.backup.*").each { |f| File.delete(f) }
    end
  end

  def test_multiple_consecutive_updates_no_corruption
    temp = create_temp_file(sample_markdown)

    begin
      # Perform multiple updates in sequence
      5.times do |i|
        editor = @editor_class.new(temp.path)
        editor.update_frontmatter({"iteration" => i, "status" => "iteration-#{i}"})
        result = editor.save!(backup: true)

        assert result[:success], "Iteration #{i} should succeed"

        saved_content = File.read(temp.path)
        # Verify document structure intact
        assert_includes saved_content, "---"
        assert_includes saved_content, "# Test Document"
        assert saved_content.lines.count > 10, "Document should not be corrupted to few lines"
      end

      # Verify final state
      final_content = File.read(temp.path)
      assert_includes final_content, "iteration: 4"
      assert_includes final_content, "status: iteration-4"
      assert_includes final_content, "## References"
    ensure
      temp.close
      temp.unlink
      Dir.glob("#{temp.path}.backup.*").each { |f| File.delete(f) }
    end
  end

  def test_concurrent_safe_writes_use_atomic_operations
    # Test that atomic write (temp + move) works correctly
    temp = create_temp_file(sample_markdown)

    begin
      results = []

      # Simulate multiple "concurrent" writes (sequential for test purposes)
      3.times do |i|
        content = "---\nid: test.#{i}\n---\n\nContent #{i}"
        result = @writer_class.write(temp.path, content, backup: true)
        results << result
      end

      # All should succeed
      assert results.all? { |r| r[:success] }

      # Final content should be complete (last write)
      final_content = File.read(temp.path)
      assert_includes final_content, "id: test.2"
      assert_includes final_content, "Content 2"

      # Should be properly formatted
      assert final_content.start_with?("---\n")
      assert_includes final_content, "\n---\n"
    ensure
      temp.close
      temp.unlink
      Dir.glob("#{temp.path}.backup.*").each { |f| File.delete(f) }
    end
  end
end
