# frozen_string_literal: true
require_relative "../../test_helper"

class DeliveryCommandTest < AceAssignTestCase
  def command_with(coordinator)
    command = Ace::Assign::CLI::Commands::Delivery.new
    command.define_singleton_method(:build_delivery) { coordinator }
    command
  end

  def test_passes_exact_evidence_references_and_serializes_projection
    with_temp_cache do |directory|
      path = File.join(directory, "tests.json")
      reference = {"attempt_id" => "test-attempt", "receipt_digest" => "digest"}
      File.write(path, JSON.generate(reference))
      received = nil
      coordinator = Object.new
      coordinator.define_singleton_method(:perform) do |**arguments|
        received = arguments
        {"candidate_head" => "candidate", "delivery" => []}
      end
      output = capture_io do
        command_with(coordinator).call(assignment: "assignment", attempt: "attempt", operation: "ready", tests: path)
      end
      assert_equal reference, received[:tests]
      assert_nil received[:review]
      assert_equal "candidate", JSON.parse(output.first)["candidate_head"]
    end
  end

  def test_invalid_input_and_rejected_evidence_fail_without_success_output
    with_temp_cache do |directory|
      path = File.join(directory, "invalid.json")
      File.write(path, "[]")
      coordinator = Object.new
      coordinator.define_singleton_method(:perform) { |**_| flunk "Invalid input reached coordinator" }
      assert_raises(Ace::Support::Cli::Error) do
        command_with(coordinator).call(assignment: "assignment", attempt: "attempt", operation: "ready", tests: path)
      end
      coordinator.define_singleton_method(:perform) do |**_|
        raise Ace::Assign::AttemptErrors::ReceiptRejected, "Evidence rejected"
      end
      output = capture_io do
        assert_raises(Ace::Support::Cli::Error) do
          command_with(coordinator).call(assignment: "assignment", attempt: "attempt", operation: "ready")
        end
      end
      assert_empty output.first
    end
  end
end
