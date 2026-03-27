# frozen_string_literal: true

require_relative "../test_helper"

class PresetInferrerTest < AceAssignTestCase
  def test_infer_from_assignment_returns_session_name
    with_temp_cache do |cache_dir|
      source_path = File.join(cache_dir, "job.yml")
      File.write(source_path, {
        "session" => {"name" => "custom-preset"}
      }.to_yaml)

      assignment = Ace::Assign::Models::Assignment.new(
        id: "abc123",
        name: "test",
        created_at: Time.now,
        source_config: source_path,
        cache_dir: cache_dir
      )

      inferred = Ace::Assign::Molecules::PresetInferrer.infer_from_assignment(assignment)
      assert_equal "custom-preset", inferred
    end
  end

  def test_infer_from_assignment_falls_back_to_default
    with_temp_cache do |cache_dir|
      assignment = Ace::Assign::Models::Assignment.new(
        id: "abc123",
        name: "test",
        created_at: Time.now,
        source_config: File.join(cache_dir, "missing.yml"),
        cache_dir: cache_dir
      )

      inferred = Ace::Assign::Molecules::PresetInferrer.infer_from_assignment(assignment)
      assert_equal "work-on-task", inferred
    end
  end
end
