# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/candidate_transfer"
require "ace/assign/authority/transfer_codec"
require "ace/assign/molecules/evidence_journal"

module Ace
  module Assign
    # Explicit offline real-project fixture. The local manifest binds a prior
    # immutable source export; absence is not an installed acceptance claim.
    class CandidateProjectReadinessTest < AceAssignTestCase
      def test_real_project_candidate_fits_transport_and_materializes_without_filtering
        path = File.expand_path("../../../.ace-local/ei9-candidate-readiness/manifest.json", __dir__)
        skip "requires explicit hash-bound offline project fixture" unless File.file?(path)
        manifest = JSON.parse(File.binread(path))
        bytes = File.binread(manifest.fetch("bundle"))
        assert_equal manifest.fetch("bytes"), bytes.bytesize
        assert_equal manifest.fetch("sha256"), Digest::SHA256.hexdigest(bytes)
        Dir.mktmpdir("ace-real-candidate-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0o700, root)
          codec = Authority::TransferCodec.new(root: root)
          descriptor = codec.descriptor([bytes], purpose: :candidate)
          assert_equal bytes.bytesize, descriptor.fetch("bytes")
          transfer = Authority::CandidateTransfer.new(root: root)
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = transfer.materialize_repository(bytes: bytes, size: bytes.bytesize,
            sha256: manifest.fetch("sha256"), head: manifest.fetch("head"), tree: manifest.fetch("tree"), root: root)
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
          assert_equal manifest.fetch("head"), result.fetch("head")
          assert_equal manifest.fetch("tree"), result.fetch("tree")
          # .git is administration created by materialize_repository, never a
          # tracked candidate path (the production path guard forbids it).
          entries = Dir.glob("**/*", File::FNM_DOTMATCH, base: result.fetch("directory")).reject { |entry|
            entry == "." || entry == ".git" || entry.start_with?(".git/") }
          files = entries.reject { |entry| File.directory?(File.join(result.fetch("directory"), entry)) && !File.symlink?(File.join(result.fetch("directory"), entry)) }
          assert_equal manifest.fetch("entries"), files.size
          expanded = files.sum do |entry|
            file = File.join(result.fetch("directory"), entry)
            File.symlink?(file) ? File.readlink(file).bytesize : File.size(file)
          end
          assert_equal manifest.fetch("expanded_bytes"), expanded
          assert_operator elapsed, :<=, Authority::CandidateTransfer::DEADLINE
          metrics = {"scope" => "offline-real-project-source-readiness", "head" => manifest.fetch("head"),
            "bundle_bytes" => bytes.bytesize, "expanded_bytes" => expanded, "entries" => files.size,
            "materialize_seconds" => elapsed}
          if manifest["before"]
            before = manifest.fetch("before")
            old_bytes = File.binread(before.fetch("bundle"))
            assert_equal before.fetch("sha256"), Digest::SHA256.hexdigest(old_bytes)
            input = ->(selected, body) { {bytes: body, sha256: selected.fetch("sha256"), size: selected.fetch("bytes"),
              head: selected.fetch("head"), tree: selected.fetch("tree")} }
            began = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            transfer.with_head_comparison(before: input.call(before, old_bytes), after: input.call(manifest, bytes),
              before_base: before.fetch("head"), after_base: before.fetch("head")) do |view|
              context = view.context
              assert_equal before.fetch("entries"), context.dig("inventories", "reviewed_head", "entries").size
              assert_equal manifest.fetch("entries"), context.dig("inventories", "candidate_head", "entries").size
              encoded = JSON.generate(context)
              assert_operator encoded.bytesize, :<=, Ace::Review::Atoms::CampaignContract::MAX_HEAD_CONTEXT_BYTES
              assert_equal %w[base_delta candidate_delta current_scope original_scope], context.fetch("changes").keys.sort
              metrics["context_bytes"] = encoded.bytesize
              metrics["context_sha256"] = Digest::SHA256.hexdigest(encoded)
            end
            metrics["comparison_seconds"] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - began
            assert_operator metrics.fetch("comparison_seconds"), :<=, Authority::CandidateTransfer::DEADLINE
          end
          # Storage boundary only: create an unreferenced immutable Git commit
          # with the actual bundle blob. This invents no assignment events and
          # is not a canonical execution/admission or publication receipt.
          directory = result.fetch("directory")
          command = lambda do |*arguments, **options|
            transfer.send(:git, directory, Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30, *arguments, **options).strip
          end
          oid = command.call("hash-object", "-w", "--stdin", stdin_data: bytes)
          bundles = command.call("mktree", stdin_data: "100644 blob #{oid}\treadiness\n")
          candidates = command.call("mktree", stdin_data: "040000 tree #{bundles}\tbundles\n")
          tree = command.call("mktree", stdin_data: "040000 tree #{candidates}\tcandidates\n")
          commit = command.call("-c", "user.name=ACE fixture", "-c", "user.email=fixture@example.invalid",
            "commit-tree", tree, "-m", "Candidate blob storage fixture")
          journal = Molecules::EvidenceJournal.new(repo_root: directory, checkout_root: File.join(root, "unused-projection"))
          stored = journal.bounded_blob("candidates/bundles/readiness", commit: commit, max_bytes: Authority::CandidateTransfer::MAX_BYTES)
          assert_equal manifest.fetch("sha256"), Digest::SHA256.hexdigest(stored)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.bounded_blob("candidates/bundles/readiness", commit: commit, max_bytes: Authority::CandidateTransfer::MAX_BYTES + 1)
          end
          metrics["blob_storage_bytes"] = stored.bytesize
          puts JSON.generate(metrics)
        end
      end
    end
  end
end
