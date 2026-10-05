# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/evidence_transfer"
require "open3"

module Ace
  module Assign
    class EvidenceTransferTest < AceAssignTestCase
      def with_staging
        Dir.mktmpdir("ace-evidence-test-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          yield root
        end
      end

      def artifact(root, name, bytes)
        path = File.join(root, name)
        FileUtils.mkdir_p(File.dirname(path), mode: 0700)
        File.binwrite(path, bytes)
        File.chmod(0600, path)
        {"ref" => name, "sha256" => Digest::SHA256.hexdigest(bytes)}
      end

      def collect(root, references)
        Authority::EvidenceTransfer.read_staged(root: root, evidence: references)
      end

      def test_collects_exact_private_bytes_without_changing_handler_paths
        with_staging do |root|
          bytes = "attestation\x00\r\n".b
          reference = artifact(root, "results/receipt", bytes)
          assert_equal [bytes], collect(root, [reference])
          assert_equal bytes, File.binread(File.join(root, "results/receipt"))
          assert_equal "results/receipt", reference["ref"]
          assert_equal ["".b], collect(root, [artifact(root, "empty", "")])
        end
      end

      def test_refuses_changed_bytes_traversal_absolute_paths_and_extra_fields
        with_staging do |root|
          reference = artifact(root, "receipt", "accepted")
          File.write(File.join(root, "receipt"), "changed")
          [reference, reference.merge("ref" => "../receipt"), reference.merge("ref" => "/receipt"),
            reference.merge("ref" => "results/../receipt"), reference.merge("path" => root)].each do |invalid|
            assert_raises(AttemptErrors::ReceiptRejected) { collect(root, [invalid]) }
          end
        end
      end

      def test_refuses_leaf_ancestor_symlinks_and_hardlinks
        with_staging do |root|
          reference = artifact(root, "private/receipt", "accepted")
          File.symlink("private/receipt", File.join(root, "link"))
          File.symlink("private", File.join(root, "linked-parent"))
          File.link(File.join(root, "private/receipt"), File.join(root, "hardlink"))
          %w[link linked-parent/receipt hardlink private/receipt].each do |path|
            assert_raises(AttemptErrors::ReceiptRejected) { collect(root, [reference.merge("ref" => path)]) }
          end
        end
      end

      def test_refuses_shared_writable_leaf_and_oversized_file_count_or_aggregate
        with_staging do |root|
          reference = artifact(root, "receipt", "accepted")
          File.chmod(0660, File.join(root, "receipt"))
          assert_raises(AttemptErrors::ReceiptRejected) { collect(root, [reference]) }
          oversized = artifact(root, "oversized", "x" * (64 * 1024 + 1))
          assert_raises(AttemptErrors::ReceiptRejected) { collect(root, [oversized]) }
          assert_raises(AttemptErrors::ReceiptRejected) { collect(root, Array.new(17, reference)) }
          references = 5.times.map { |index| artifact(root, "part-#{index}", "x" * (64 * 1024)) }
          assert_raises(AttemptErrors::ReceiptRejected) { collect(root, references) }
        end
      end

      def test_fifo_is_refused_without_waiting_for_an_unrelated_writer
        with_staging do |root|
          path = File.join(root, "fifo")
          _output, error, status = Open3.capture3("mkfifo", path)
          assert status.success?, error
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          assert_raises(AttemptErrors::ReceiptRejected) do
            collect(root, [{"ref" => "fifo", "sha256" => Digest::SHA256.hexdigest("")}])
          end
          assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1
        end
      end
    end
  end
end
