# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/transfer_codec"
require "ace/assign/authority/receipt_transfer"

module Ace
  module Assign
    class ReceiptTransferTest < AceAssignTestCase
      def receipt(artifacts)
        JSON.generate("artifacts" => artifacts.each_with_index.map do |bytes, index|
          {"path" => "check-#{index}", "sha256" => Digest::SHA256.hexdigest(bytes)}
        end)
      end

      def decode(parts, sha: Digest::SHA256.hexdigest(parts.first))
        Dir.mktmpdir("receipt-transfer-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          codec = Authority::TransferCodec.new(root: root)
          descriptor = codec.descriptor(parts, purpose: :receipt_artifacts)
          reader, writer = UNIXSocket.pair
          sender = Thread.new { writer.write(parts.join); writer.shutdown(Socket::SHUT_WR) }
          codec.receive(reader, descriptor: descriptor, purpose: :receipt_artifacts,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5) do |input|
            Authority::ReceiptTransfer.decode(input: input, receipt_sha256: sha, artifact_field: "artifacts", reference_key: "path")
          end
        ensure
          reader&.close
          writer&.close
          sender&.join
        end
      end

      def test_receipt_first_identity_and_sixteen_ordered_binary_artifacts
        artifacts = Array.new(16) { |index| "artifact-#{index}\x00\r\n".b }
        bytes = receipt(artifacts)
        decoded = decode([bytes] + artifacts)
        assert_equal artifacts, decoded.fetch(:artifacts)
        assert_equal Digest::SHA256.hexdigest(bytes), decoded.fetch(:receipt_sha256)
        assert_equal JSON.parse(bytes), decoded.fetch(:receipt)
      end

      def test_missing_duplicate_reordered_and_unbound_parts_are_refused
        artifacts = %w[one two]
        bytes = receipt(artifacts)
        [[bytes, "one"], [bytes, bytes, "one", "two"], [bytes, "two", "one"], ["one", bytes, "two"]].each do |parts|
          assert_raises(AttemptErrors::ReceiptRejected) { decode(parts) }
        end
        assert_raises(AttemptErrors::ReceiptRejected) { decode([bytes] + artifacts, sha: "a" * 64) }
      end

      def test_forbidden_or_duplicate_artifact_identity_and_invalid_receipt_are_refused
        one = {"path" => "same", "sha256" => Digest::SHA256.hexdigest("one")}
        assert_raises(AttemptErrors::ReceiptRejected) { decode([JSON.generate("artifacts" => [one, one]), "one", "one"]) }
        assert_raises(AttemptErrors::ReceiptRejected) { decode([JSON.generate("artifacts" => [], "credentials" => "forbidden")]) }
        assert_raises(AttemptErrors::ReceiptRejected) { decode(["not-json"]) }
      end
    end
  end
end
