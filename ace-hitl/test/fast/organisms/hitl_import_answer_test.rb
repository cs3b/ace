# frozen_string_literal: true

require_relative "../../test_helper"

class HitlImportAnswerTest < AceHitlTestCase
  def test_replay_preserves_bytes_and_conflict_preserves_original_answer
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root,
        config: {"hitl" => {"root_dir" => root}})
      event = manager.create("Proceed?", questions: ["Proceed?"])
      assert_equal "Yes", manager.accept_answer(event.id, answer: "Yes").answer
      bytes = File.binread(event.file_path)
      assert_equal "Yes", manager.accept_answer(event.id, answer: "Yes").answer
      assert_equal bytes, File.binread(event.file_path)
      assert_raises(Ace::Hitl::Organisms::HitlManager::AnswerConflictError) do
        manager.accept_answer(event.id, answer: "No")
      end
      assert_equal bytes, File.binread(event.file_path)
    end
  end
end
