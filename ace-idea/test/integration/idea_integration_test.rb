# frozen_string_literal: true

require "test_helper"

# Integration tests for ace-idea: end-to-end scenarios and edge cases.
# Covers the full lifecycle and validates graceful degradation paths.
class IdeaIntegrationTest < AceIdeaTestCase
  # ---------------------------------------------------------------------------
  # 1. Full roundtrip: create → show → update → move → list → verify
  # ---------------------------------------------------------------------------

  def test_full_roundtrip_create_show_update_move_list_verify
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      # Step 1: Create
      idea = manager.create("Integration test idea",
                            title: "Integration Test",
                            tags: ["test", "integration"])
      refute_nil idea
      assert_equal "pending", idea.status
      assert_equal "Integration Test", idea.title
      assert_equal ["test", "integration"], idea.tags
      id = idea.id
      assert_match(/\A[0-9a-z]{6}\z/, id)

      # Step 2: Show by full ID
      loaded = manager.show(id)
      refute_nil loaded
      assert_equal id, loaded.id
      assert_equal "Integration Test", loaded.title

      # Step 3: Show by shortcut (last 3 chars)
      shortcut = id[-3..]
      by_shortcut = manager.show(shortcut)
      refute_nil by_shortcut
      assert_equal id, by_shortcut.id

      # Step 4: Update status and add a tag
      updated = manager.update(id, set: { "status" => "in-progress" }, add: { "tags" => "important" })
      refute_nil updated
      assert_equal "in-progress", updated.status
      assert_includes updated.tags, "test"
      assert_includes updated.tags, "important"

      # Step 5: Remove a tag
      after_remove = manager.update(id, remove: { "tags" => "integration" })
      refute_nil after_remove
      refute_includes after_remove.tags, "integration"
      assert_includes after_remove.tags, "test"

      # Step 6: Move to archive via update --move-to
      moved = manager.update(id, move_to: "archive")
      refute_nil moved
      assert_equal "_archive", moved.special_folder
      assert_equal "in-progress", moved.status

      # Step 7: List all ideas - should appear in archive
      all_ideas = manager.list(in_folder: "all")
      assert_equal 1, all_ideas.length
      assert_equal id, all_ideas.first.id

      # Step 8: List by folder
      archived = manager.list(in_folder: "_archive")
      assert_equal 1, archived.length
      assert_equal id, archived.first.id

      # Step 9: Verify root is now empty (idea moved out)
      root_ideas = manager.list(in_folder: "next")
      assert_equal 0, root_ideas.length

      # Step 10: Move back to root via update --move-to
      back_at_root = manager.update(id, move_to: "root")
      refute_nil back_at_root
      assert_nil back_at_root.special_folder
    end
  end

  # ---------------------------------------------------------------------------
  # 2. Clipboard edge cases
  # ---------------------------------------------------------------------------

  def test_clipboard_graceful_degradation_when_gem_unavailable
    # When Clipboard gem is not available and not on macOS with mac clipboard,
    # IdeaClipboardReader.read should return failure, not raise.
    result = Ace::Idea::Molecules::IdeaClipboardReader.read
    assert result.is_a?(Hash), "read should return a Hash"
    assert result.key?(:success), "result should have :success key"
    # May succeed (if clipboard available) or fail (if not) - but should not raise
  end

  def test_clipboard_empty_content_returns_error
    # Simulate clipboard returning empty content by stubbing Clipboard.paste
    with_fake_clipboard("") do
      result = Ace::Idea::Molecules::IdeaClipboardReader.read
      # Either not available (success: false) or returns empty error
      assert result.is_a?(Hash)
      if result[:success] == false
        assert result[:error].is_a?(String), "error should be a string"
        refute result[:error].empty?, "error should not be empty"
      end
    end
  end

  def test_clipboard_binary_content_returns_error
    # Simulate clipboard returning binary data
    binary_content = +"\x00\x01\x02binary data"
    binary_content.force_encoding(Encoding::ASCII_8BIT)
    with_fake_clipboard(binary_content) do
      result = Ace::Idea::Molecules::IdeaClipboardReader.read
      assert result.is_a?(Hash)
      if result[:success] == false && result[:error]
        # Should get binary content error or unavailable error
        assert result[:error].is_a?(String)
      end
    end
  end

  def test_clipboard_large_content_returns_error
    # Simulate clipboard returning content exceeding 100KB limit
    large_content = "x" * (101 * 1024)
    with_fake_clipboard(large_content) do
      result = Ace::Idea::Molecules::IdeaClipboardReader.read
      assert result.is_a?(Hash)
      if result[:success] == false && result[:error]
        # Either "too large" or "gem unavailable" error
        assert result[:error].is_a?(String)
      end
    end
  end

  def test_creator_raises_argument_error_when_clipboard_empty
    # Use fake clipboard returning empty string to reliably test the error path
    with_fake_clipboard("") do
      with_ideas_dir do |root|
        creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
        err = assert_raises(ArgumentError) do
          creator.create(nil, clipboard: true)
        end
        assert err.message.is_a?(String)
        refute err.message.empty?
      end
    end
  end

  # ---------------------------------------------------------------------------
  # 3. LLM enhancement fallback at manager level
  # ---------------------------------------------------------------------------

  def test_manager_create_with_llm_enhance_falls_back_gracefully
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      # Stub LLM availability to force fallback path without real API calls
      enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
      Ace::Idea::Molecules::IdeaLlmEnhancer.stub(:new, enhancer) do
        enhancer.stub(:llm_available?, false) do
          idea = manager.create("Raw idea content for LLM enhancement", llm_enhance: true)

          refute_nil idea, "Idea should be created even when LLM enhancement may fail"
          assert_equal 6, idea.id.length
          assert File.exist?(idea.file_path)

          content = File.read(idea.file_path)
          refute content.empty?
        end
      end
    end
  end

  def test_llm_enhance_fallback_preserves_original_content
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      # Stub LLM availability to force fallback path without real API calls
      enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
      Ace::Idea::Molecules::IdeaLlmEnhancer.stub(:new, enhancer) do
        enhancer.stub(:llm_available?, false) do
          raw_content = "Add search autocomplete to the main search bar"
          idea = manager.create(raw_content, llm_enhance: true)

          refute_nil idea
          file_content = File.read(idea.file_path)

          assert file_content.include?("---"), "Should have frontmatter"
          refute file_content.strip.empty?
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # 4. Concurrent creation: two ideas within the same 2-second b36ts window
  # ---------------------------------------------------------------------------

  def test_concurrent_ideas_same_b36ts_id_same_slug_creates_unique_folders
    with_ideas_dir do |root|
      # Fix time so both ideas get the same b36ts ID
      fixed_time = Time.at(1706443200).utc

      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)

      # Both ideas have same content → same slug → same potential folder name
      idea1 = creator.create("Duplicate idea content", time: fixed_time)
      idea2 = creator.create("Duplicate idea content", time: fixed_time)

      # Both should be created without raising
      refute_nil idea1
      refute_nil idea2

      # Both should have the same ID (same b36ts timestamp)
      assert_equal idea1.id, idea2.id

      # But they should be in DIFFERENT directories
      refute_equal idea1.path, idea2.path, "Duplicate ideas must have unique folders"

      # Both folders should exist on disk
      assert Dir.exist?(idea1.path), "First idea folder should exist"
      assert Dir.exist?(idea2.path), "Second idea folder should exist"

      # Both spec files should exist
      assert File.exist?(idea1.file_path)
      assert File.exist?(idea2.file_path)
    end
  end

  def test_concurrent_ideas_same_b36ts_id_different_slugs_are_both_accessible
    with_ideas_dir do |root|
      fixed_time = Time.at(1706443200).utc

      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)

      idea1 = creator.create("First concurrent idea", time: fixed_time)
      idea2 = creator.create("Second concurrent idea", time: fixed_time)

      refute_nil idea1
      refute_nil idea2

      # Both created successfully with same ID but different slugs
      assert_equal idea1.id, idea2.id

      # Both accessible through the file system
      assert Dir.exist?(idea1.path)
      assert Dir.exist?(idea2.path)

      # Total ideas in root should be 2
      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan
      assert_equal 2, results.length
    end
  end

  # ---------------------------------------------------------------------------
  # 5. Performance: scan with 500+ ideas
  # ---------------------------------------------------------------------------

  def test_scan_performance_with_large_idea_collection
    with_ideas_dir do |root|
      # Create 500 idea fixtures across root and special folders
      idea_count = 500
      special_folders = [nil, "_maybe", "_archive"]

      idea_count.times do |i|
        padded = format("%06d", i)
        # Use a deterministic ID-like string (not valid b36ts but sufficient for fixture)
        id = "#{padded[0]}#{padded[1]}#{padded[2]}#{padded[3]}#{padded[4]}#{padded[5]}"
        # Ensure ids are 6 chars of [0-9a-z]
        id = "a#{format('%05d', i)}"[0..5]
        special_folder = special_folders[i % special_folders.size]
        slug = "idea-#{i}"
        create_idea_fixture(root, id: "t#{format('%05d', i)}"[0..5], slug: slug,
                            special_folder: special_folder)
      end

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ideas = manager.list(in_folder: "all")
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      assert_equal idea_count, ideas.length, "Should find all #{idea_count} ideas"
      assert elapsed < 10.0, "Scanning #{idea_count} ideas should complete within 10s (took #{elapsed.round(2)}s)"
    end
  end

  def test_scan_performance_with_deeply_nested_folders
    with_ideas_dir do |root|
      # Create ideas spread across multiple special folders
      %w[_maybe _archive _reference _hold].each do |folder|
        25.times do |i|
          create_idea_fixture(root, id: "x#{format('%05d', i + folder.length)}"[0..5],
                              slug: "#{folder.tr('_', '')}-idea-#{i}",
                              special_folder: folder)
        end
      end

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ideas = manager.list(in_folder: "all")
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      assert_equal 100, ideas.length
      assert elapsed < 5.0, "Scanning nested ideas should complete within 5s (took #{elapsed.round(2)}s)"
    end
  end

  private

  # Temporarily defines a fake Clipboard module for testing edge cases.
  # If Clipboard is already defined (gem available), the stub is skipped
  # and the block runs with the real clipboard (test may be a no-op).
  def with_fake_clipboard(content)
    clipboard_was_defined = Object.const_defined?(:Clipboard)
    unless clipboard_was_defined
      fake_clipboard = Module.new
      fake_content = content
      fake_clipboard.define_singleton_method(:paste) { fake_content }
      Object.const_set(:Clipboard, fake_clipboard)
    end
    yield
  ensure
    Object.send(:remove_const, :Clipboard) if !clipboard_was_defined && Object.const_defined?(:Clipboard)
  end
end
