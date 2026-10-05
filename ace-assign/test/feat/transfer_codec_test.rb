# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/transfer_codec"

module Ace
  module Assign
    class TransferCodecTest < AceAssignTestCase
      def with_codec
        Dir.mktmpdir("ace-transfer-test-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          yield Authority::TransferCodec.new(root: root), root
        end
      end

      def deadline(seconds = 2)
        Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
      end

      def with_upload(payload, eof: true)
        reader, writer = UNIXSocket.pair
        writer.write(payload)
        writer.shutdown(Socket::SHUT_WR) if eof
        yield reader
      ensure
        reader&.close
        writer&.close
      end

      def test_exact_multi_part_binary_upload_is_admitted_only_after_write_eof_and_spool_is_removed
        with_codec do |codec, root|
          parts = ["one\x00\n".b, "two\r\n".b]
          descriptor = codec.descriptor(parts, purpose: :artifacts)
          with_upload(parts.join) do |socket|
            result = codec.receive(socket, descriptor: descriptor, purpose: :artifacts, deadline: deadline) do |input|
              assert_equal 1, Dir.children(root).length
              assert_equal 0600, File.stat(File.join(root, Dir.children(root).first)).mode & 0777
              assert_equal 2, input.count
              [input.bytes(index: 0), input.bytes(index: 1)]
            end
            assert_equal parts, result
          end
          assert_empty Dir.children(root)
        end
      end

      def test_short_extra_and_changed_payload_never_invoke_consumer_or_leave_spool
        with_codec do |codec, root|
          descriptor = codec.descriptor(["accepted"], purpose: :candidate)
          ["short", "accepted-extra", "changed!"].each do |payload|
            with_upload(payload) do |socket|
              assert_raises(AttemptErrors::ReceiptRejected) do
                codec.receive(socket, descriptor: descriptor, purpose: :candidate, deadline: deadline) { flunk "invalid upload admitted" }
              end
            end
            assert_empty Dir.children(root)
          end
        end
      end

      def test_missing_eof_hits_shared_deadline_without_mutation_or_retained_spool
        with_codec do |codec, root|
          descriptor = codec.descriptor(["accepted"], purpose: :candidate)
          with_upload("accepted", eof: false) do |socket|
            assert_raises(Timeout::Error) do
              codec.receive(socket, descriptor: descriptor, purpose: :candidate, deadline: deadline(0.05)) { flunk "EOF missing" }
            end
          end
          assert_empty Dir.children(root)
        end
      end

      def test_fixed_purpose_limits_and_descriptor_shape_refuse_before_spool
        with_codec do |codec, root|
          descriptor = codec.descriptor(["accepted"], purpose: :candidate)
          oversized = descriptor.merge("bytes" => 64 * 1024 * 1024 + 1)
          assert_raises(AttemptErrors::ReceiptRejected) { codec.validate!(oversized, :candidate) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.validate!(descriptor.merge("path" => "/tmp/override"), :candidate) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(["x" * (64 * 1024 + 1)], purpose: :artifacts) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(Array.new(17, ""), purpose: :artifacts) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor([""], purpose: :candidate) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.validate!(descriptor, :request_selected) }
          assert_empty Dir.children(root)
        end
      end

      def test_receipt_purpose_preserves_all_sixteen_artifacts_and_separate_full_capacity
        with_codec do |codec, root|
          parts = ["r" * (16 * 1024)] + Array.new(16) { "e" * (16 * 1024) }
          descriptor = codec.descriptor(parts, purpose: :receipt_artifacts)
          assert_equal 272 * 1024, descriptor.fetch("bytes")
          reader, writer = UNIXSocket.pair
          sender = Thread.new do
            writer.write(parts.join)
            writer.shutdown(Socket::SHUT_WR)
          end
          received = codec.receive(reader, descriptor: descriptor, purpose: :receipt_artifacts, deadline: deadline(5)) do |input|
            Array.new(input.count) { |index| input.bytes(index: index) }
          end
          sender.value
          assert_equal parts, received
          assert_empty Dir.children(root)
        ensure
          reader&.close
          writer&.close
          sender&.join
        end
      end

      def test_receipt_purpose_limits_do_not_widen_generic_artifacts_or_trade_evidence_for_receipt_capacity
        with_codec do |codec, root|
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(["r" * (16 * 1024 + 1)], purpose: :receipt_artifacts) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(["", "e"], purpose: :receipt_artifacts) }
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(["r"] + Array.new(17, "e"), purpose: :receipt_artifacts) }
          assert_raises(AttemptErrors::ReceiptRejected) do
            codec.descriptor(["r", "e" * (64 * 1024 + 1)], purpose: :receipt_artifacts)
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            codec.descriptor(["r"] + Array.new(5) { "e" * (64 * 1024) }, purpose: :receipt_artifacts)
          end
          assert_raises(AttemptErrors::ReceiptRejected) { codec.descriptor(Array.new(17, "e"), purpose: :artifacts) }
          assert_empty Dir.children(root)
        end
      end

      def test_export_uses_exact_binary_bytes_and_refuses_mismatched_descriptor
        with_codec do |codec, _root|
          parts = ["first\x00".b, "second\n".b]
          descriptor = codec.descriptor(parts, purpose: :artifacts)
          reader, writer = UNIXSocket.pair
          codec.send(writer, parts: parts, descriptor: descriptor, purpose: :artifacts, deadline: deadline)
          writer.shutdown(Socket::SHUT_WR)
          assert_equal parts.join, reader.read.b
          assert_raises(AttemptErrors::ReceiptRejected) do
            codec.send(writer, parts: ["different"], descriptor: descriptor, purpose: :artifacts, deadline: deadline)
          end
        ensure
          reader&.close
          writer&.close
        end
      end

      def test_consumer_failure_removes_only_new_spool_and_preserves_existing_private_files
        with_codec do |codec, root|
          File.write(File.join(root, "preserved"), "private state")
          descriptor = codec.descriptor(["accepted"], purpose: :candidate)
          with_upload("accepted") do |socket|
            assert_raises(AttemptErrors::Conflict) do
              codec.receive(socket, descriptor: descriptor, purpose: :candidate, deadline: deadline) do |_input|
                raise AttemptErrors::Conflict, "generation changed"
              end
            end
          end
          assert_equal ["preserved"], Dir.children(root)
          assert_equal "private state", File.read(File.join(root, "preserved"))
        end
      end
    end
  end
end
