# frozen_string_literal: true
require_relative "../test_helper"
require "ace/coworker/molecules/execution_evidence"

class ExecutionEvidenceTest < AceCoworkerTestCase
  def test_follows_only_assignment_references_deduplicates_and_keeps_unknown_counts
    Dir.mktmpdir do |root|
      session = File.join(root, "session.jsonl")
      message = {"id" => "one", "type" => "message", "message" => {"role" => "assistant",
        "model" => "glm-5.3-flash", "provider" => "zai", "stopReason" => "toolUse",
        "usage" => {"input" => 10, "output" => 2, "cacheRead" => 7}}}
      File.write(session, [message, message].map { |row| JSON.generate(row) }.join("\n") + "\n")
      config = File.join(root, "worker.yml")
      File.write(config, YAML.dump({"execution" => {"session_path" => session, "agent_session" => {"agent" => "pi", "kind" => "id", "value" => "unique-session-id"}}}))
      review = File.join(root, ".ace-local/review/sessions/review-one")
      FileUtils.mkdir_p(review)
      File.write(File.join(review, "llm_metadata.yml"), YAML.dump({"execution" => {model: "glm-5.3-flash"},
        "status" => "success", "usage" => {input_tokens: 5, output_tokens: 3}}))
      reports = File.join(root, ".ace-local/assign/a1/reports")
      FileUtils.mkdir_p(reports)
      File.write(File.join(reports, "010-review.r.md"), "#{review}\n#{review}\n")
      cfg = Struct.new(:source_path, :assignment).new(config, "a1")
      reader = Ace::Coworker::Molecules::ExecutionEvidence.new(project_root: root)
      evidence = reader.read(cfg)
      assert_equal evidence, reader.read(cfg), "retry is a projection, not an accumulating counter"
      assert_equal 2, evidence["executions"].size
      pi, nested = evidence["executions"]
      assert_equal({"input" => 10, "output" => 2, "cacheRead" => 7, "cacheWrite" => nil}, pi["usage"])
      assert_equal "glm-5.3-flash", nested["model"]
      assert_nil nested["usage"]["cacheRead"]
      File.write(File.join(review, "metadata.yml"), YAML.dump({"models" => [
        {"requested_selector" => "requested", "execution" => {"model" => "actual-flash"},
         "status" => "success", "usage" => {"input_tokens" => 12, "output_tokens" => 3}},
        {"requested_selector" => "unavailable", "status" => "failed"}]}))
      executions = reader.read(cfg)["executions"]
      assert_equal 3, executions.size
      assert_equal "actual-flash", executions[1]["model"]
      assert_nil executions[2]["model"], "requested model is not proof of execution"
      assert_nil executions[2]["usage"]
    end
  end
end
