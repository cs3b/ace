# frozen_string_literal: true
require_relative "../../test_helper"
module Ace
  module Assign
    class ProtectedSubmissionTest < AceAssignTestCase
      def command_context(client)
        context = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
        context.define_singleton_method(:protected_participant?) { true }
        context.define_singleton_method(:client) { |**_| client }
        context
      end

      def test_original_bytes_and_generation_are_sent_once_and_bad_inputs_never_send
        Dir.mktmpdir("submission-") do |root|
          bundle = File.join(root, "bundle")
          receipt = File.join(root, "receipt")
          artifact = File.join(root, "artifact")
          File.binwrite(bundle, "bundle bytes")
          File.binwrite(artifact, "actual evidence")
          data = {"assignment_id" => "assignment", "attempt_id" => "attempt", "head" => "a" * 40, "verdict" => "succeeded", "artifacts" => [{"path" => "evidence", "sha256" => Digest::SHA256.hexdigest("actual evidence")}]}
          File.binwrite(receipt, JSON.generate(data))
          calls = []
          client = Object.new
          client.define_singleton_method(:call) { |operation, params, **options| calls << [operation, params, options]; Struct.new(:data).new({"generation" => 8}) }
          common = ["--mapping", "mapping", "--assignment", "assignment", "--attempt", "attempt", "--head", "a" * 40,
            "--candidate-generation", "2", "--expected-generation", "7", "--mutation", "stable"]
          Authority::ProtectedAssignmentContext.stub(:load, command_context(client)) do
            capture_io { assert_equal 0, CLI.start(["submit-candidate", *common, "--bundle", bundle]) }
            capture_io { assert_equal 0, CLI.start(["submit-result", *common, "--receipt", receipt, "--artifact", artifact]) }
            assert_equal %w[submit_candidate submit_result], calls.map(&:first)
            assert_equal [7, 7], calls.map { |call| call[1].fetch("expected_generation") }
            assert_equal ["bundle bytes"], calls.first.last.fetch(:upload_parts)
            assert_equal [File.binread(receipt), "actual evidence"], calls.last.last.fetch(:upload_parts)
            second = File.join(root, "second-artifact")
            File.binwrite(second, "second evidence")
            data["artifacts"] << {"path" => "second", "sha256" => Digest::SHA256.hexdigest("second evidence")}
            File.binwrite(receipt, JSON.generate(data))
            capture_io { assert_equal 0, CLI.start(["submit-result", *common, "--receipt", receipt, "--artifact", artifact, "--artifact", second]) }
            assert_equal [File.binread(receipt), "actual evidence", "second evidence"], calls.last.last.fetch(:upload_parts)
            data["attempt_id"] = "foreign"
            File.binwrite(receipt, JSON.generate(data))
            assert_raises(Ace::Support::Cli::Error) { CLI.start(["submit-result", *common, "--receipt", receipt, "--artifact", artifact, "--artifact", second]) }
            data["attempt_id"] = "attempt"
            data["unsupported"] = true
            File.binwrite(receipt, JSON.generate(data))
            assert_raises(Ace::Support::Cli::Error) { CLI.start(["submit-result", *common, "--receipt", receipt, "--artifact", artifact, "--artifact", second]) }
            data.delete("unsupported")
            File.binwrite(receipt, JSON.generate(data))
            File.binwrite(artifact, "changed")
            mismatch = assert_raises(AttemptErrors::ReceiptRejected) do
              CLI.start(["submit-result", *common, "--receipt", receipt, "--artifact", artifact, "--artifact", second])
            end
            assert_equal "receipt artifact part differs from declaration", mismatch.message
            assert_equal 3, calls.size
            File.binwrite(receipt, '{"artifacts":[],"artifacts":[]}')
            assert_raises(Ace::Support::Cli::Error) { CLI.start(["submit-result", *common, "--receipt", receipt]) }
            link = File.join(root, "linked")
            File.symlink(bundle, link)
            assert_raises(Ace::Support::Cli::Error) { CLI.start(["submit-candidate", *common, "--bundle", link]) }
            assert_equal 3, calls.size
          end
        end
      end
    end
  end
end
