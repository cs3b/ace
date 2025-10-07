# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/idea_writer"
require "fileutils"
require "tmpdir"

# Test that IdeaWriter preserves clipboard and note flags through merge_options_with_config
class IdeaWriterFlagPreservationTest < AceTaskflowTestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @config = {
      "directory" => File.join(@temp_dir, "ideas"),
      "template" => "%{content}"
    }
    @writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_clipboard_flag_is_preserved
    # Call private method merge_options_with_config via send
    result = @writer.send(:merge_options_with_config, clipboard: true)

    assert_equal true, result[:clipboard], "clipboard flag should be preserved"
  end

  def test_clipboard_flag_false_is_preserved
    result = @writer.send(:merge_options_with_config, clipboard: false)

    assert_equal false, result[:clipboard], "clipboard: false should be preserved"
  end

  def test_clipboard_flag_nil_is_not_set
    result = @writer.send(:merge_options_with_config, {})

    refute result.key?(:clipboard), "clipboard should not be set when not provided"
  end

  def test_note_flag_is_preserved
    result = @writer.send(:merge_options_with_config, note: "explicit note text")

    assert_equal "explicit note text", result[:note], "note flag should be preserved"
  end

  def test_clipboard_and_note_together
    result = @writer.send(:merge_options_with_config, {
      clipboard: true,
      note: "my note",
      git_commit: true
    })

    assert_equal true, result[:clipboard]
    assert_equal "my note", result[:note]
    assert_equal true, result[:git_commit]
  end

  def test_all_flags_preserved_together
    result = @writer.send(:merge_options_with_config, {
      clipboard: true,
      note: "note text",
      git_commit: true,
      llm_enhance: true,
      location: "backlog",
      title: "custom title",
      tags: "tag1,tag2"
    })

    assert_equal true, result[:clipboard]
    assert_equal "note text", result[:note]
    assert_equal true, result[:git_commit]
    assert_equal true, result[:llm_enhance]
    assert_equal "backlog", result[:location]
    assert_equal "custom title", result[:title]
    assert_equal "tag1,tag2", result[:tags]
  end
end
