# frozen_string_literal: true

require "ace/runtime/molecules/protected_artifact_set"
require_relative "cleanup_result_protection"

module Ace
  module Assign
    module Authority
      # The existing service evidence owner authenticates this complete pair.
      # Root-private archives remain outside the authority evidence graph.
      module ServiceCleanupEvidence
        ROOT_SELECTION_SCHEMA = "ace.protected-workspace-prune-root-selection/v1"
        ROOT_RECEIPT_SCHEMA = "ace.protected-workspace-prune-receipt/v1"
        ROOT_SELECTION_FIELDS = %w[schema request_id input_digest operation_owner_binding_digest receipt_ref].freeze
        ROOT_INSPECTION_SELECTION_SCHEMA = "ace.protected-workspace-prune-inspection-selection/v1"
        ROOT_INSPECTION_SELECTION_FIELDS = %w[schema request_id input_digest operation_owner_binding_digest inspection_ref].freeze
        ROOT_RECEIPT_FIELDS = %w[schema request_id input_digest maintenance target publication canonical_snapshots preservation removal].freeze

        # Pre-import decoding reuses the collection validator. Only the lower
        # writer's pending collection can authenticate protected storage and
        # accept a terminal update.
        def cleanup_inspection_inputs!(contents, record, challenge)
          unless record["operation"] == "prune-preserved-workspace" && contents.is_a?(Array) && contents.size == 2
            raise AttemptErrors::ReceiptRejected, "cleanup inspection requires its complete pair"
          end
          cleanup_documents!(contents, record, no_effect: true, challenge: challenge)
          true
        rescue KeyError, TypeError, JSON::ParserError, JSON::GeneratorError
          raise AttemptErrors::ReceiptRejected, "cleanup inspection pair is unavailable"
        end

        private

        def cleanup_collection!(references, record, state, pending)
          unless record["operation"] == "prune-preserved-workspace" && %w[succeeded failed-settled].include?(state) && references.size == 2
            raise AttemptErrors::ReceiptRejected, "cleanup completion requires its complete original evidence pair"
          end
          no_effect = state == "failed-settled"
          challenge = no_effect ? challenge!(record, pending: pending) : nil
          expected = no_effect ? context_for_challenge(record, challenge) : context(record)
          proof = cleanup_dispatch_context!(record, commit: pending && pending[:commit] || @journal.ref_value, pending: pending)
          contents = references.map do |reference|
            if pending && pending[:pending_events]
              @canonical.read_pending(reference, **expected, **pending.slice(:current_events, :pending_events, :blobs, :commit))
            else
              @canonical.read(reference, **expected, commit: pending && pending[:commit] || @journal.ref_value)
            end
          end
          reference, operation_bytes = cleanup_documents!(contents, record, no_effect: no_effect,
            challenge: challenge)
          path = reference.fetch("path")
          # The lower writer supplies its pending import transaction. Historical
          # consumers have only a pinned commit and never reopen mutable storage.
          if pending && pending[:pending_events]
            selected_artifacts = @cleanup_artifacts || Ace::Runtime::Molecules::ProtectedArtifactSet.new(
              protection: CleanupResultProtection.new(result_path: path, authority_gid: Process.egid))
            selected_artifacts.with do |artifacts|
              unless artifacts.read!(reference) == operation_bytes
                raise AttemptErrors::ReceiptRejected, "cleanup retained result bytes differ"
              end
              artifacts.verify_unchanged!
            end
          end
          if (view = service_read_view(pending))
            view.projection = settlement_projection(record, pending, challenge, proof)
          end
          contents.freeze
        rescue KeyError, TypeError, JSON::ParserError, JSON::GeneratorError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::ReceiptRejected, "cleanup original evidence is unavailable"
        end

        def cleanup_documents!(contents, record, no_effect:, challenge:)
          documents = contents.map { |bytes| cleanup_json!(bytes) }
          selection_schema = no_effect ? ROOT_INSPECTION_SELECTION_SCHEMA : ROOT_SELECTION_SCHEMA
          selection_fields = no_effect ? ROOT_INSPECTION_SELECTION_FIELDS : ROOT_SELECTION_FIELDS
          selection_index = documents.each_index.select { |index| documents[index]["schema"] == selection_schema }
          receipt_index = documents.each_index.select do |index|
            no_effect ? documents[index].keys.sort == ServiceEvidence::INSPECTION_FIELDS.sort : documents[index]["schema"] == ROOT_RECEIPT_SCHEMA
          end
          unless selection_index.one? && receipt_index.one?
            raise AttemptErrors::ReceiptRejected, "cleanup original evidence selection is ambiguous"
          end
          selection = documents.fetch(selection_index.first)
          receipt = documents.fetch(receipt_index.first)
          closed_cleanup!(selection, selection_fields)
          closed_cleanup!(receipt, no_effect ? ServiceEvidence::INSPECTION_FIELDS : ROOT_RECEIPT_FIELDS)
          unless [selection, receipt].all? { |value| value["request_id"] == record.fetch("request_id") && value["input_digest"] == record.fetch("input_digest") } &&
              selection["operation_owner_binding_digest"] == Atoms::EvidenceDigest.digest(record.fetch("operation_owner_binding"))
            raise AttemptErrors::ReceiptRejected, "cleanup original owner or request differs"
          end
          reference = selection.fetch(no_effect ? "inspection_ref" : "receipt_ref")
          closed_cleanup!(reference, %w[path bytes sha256])
          path = reference.fetch("path")
          operation_bytes = contents.fetch(receipt_index.first)
          unless path.is_a?(String) && path.bytesize <= 4096 && path.valid_encoding? && !path.include?("\0") &&
              path.start_with?("/") && File.expand_path(path) == path &&
              reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 65_536) &&
              reference["bytes"] == operation_bytes.bytesize && reference["sha256"] == Digest::SHA256.hexdigest(operation_bytes)
            raise AttemptErrors::ReceiptRejected, "cleanup retained result reference differs"
          end
          if no_effect
            inspection_projection!(receipt, record, challenge)
          else
            cleanup_receipt_projection!(receipt, record)
          end
          [reference, operation_bytes]
        end

        def cleanup_json!(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 65_536)
            raise AttemptErrors::ReceiptRejected, "cleanup evidence exceeds bounds"
          end
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          raise AttemptErrors::ReceiptRejected, "cleanup evidence is invalid UTF8" unless text.valid_encoding? && !text.include?("\0")
          value = JSON.parse(text, create_additions: false, max_nesting: 16, allow_duplicate_key: false, allow_comments: false)
          raise AttemptErrors::ReceiptRejected, "cleanup evidence is not an object" unless value.is_a?(Hash)
          value
        end

        def closed_cleanup!(value, fields)
          unless value.is_a?(Hash) && value.keys.sort == fields.sort
            raise AttemptErrors::ReceiptRejected, "cleanup evidence fields differ"
          end
        end

        def cleanup_receipt_projection!(receipt, record)
          preservation = receipt.fetch("preservation")
          closed_cleanup!(preservation, %w[head branch destinations manifest_sha256 inventory_sha256 file_count total_bytes private_manifest_sha256 archives_sha256])
          unless preservation["file_count"].is_a?(Integer) && preservation["file_count"].between?(0, 4096) &&
              preservation["total_bytes"].is_a?(Integer) && preservation["total_bytes"].between?(0, 256 * 1024 * 1024) &&
              %w[manifest_sha256 inventory_sha256 private_manifest_sha256 archives_sha256].all? { |key| cleanup_sha?(preservation[key]) }
            raise AttemptErrors::ReceiptRejected, "cleanup preservation observation differs"
          end
          input = receipt.slice("maintenance", "target", "publication").merge("schema" => "ace.protected-workspace-prune/v1",
            "preservation" => preservation.slice("head", "branch", "destinations", "manifest_sha256"))
          unless Atoms::EvidenceDigest.digest(input) == record.fetch("input_digest") &&
              receipt.fetch("maintenance") == record.slice("project_id", "mapping_id", "assignment_id", "attempt_id")
            raise AttemptErrors::ReceiptRejected, "cleanup original input differs"
          end
          snapshots = receipt.fetch("canonical_snapshots")
          unless snapshots.is_a?(Array) && snapshots.size.between?(1, 256)
            raise AttemptErrors::ReceiptRejected, "cleanup canonical snapshots exceed bounds"
          end
          snapshots.each do |snapshot|
            closed_cleanup!(snapshot, %w[mapping_id journal_commit binding_event_digest release_event_digest proof_event_digest])
            unless snapshot["mapping_id"].is_a?(String) && snapshot["mapping_id"].match?(Molecules::JournalMutation::ID) &&
                snapshot["journal_commit"].is_a?(String) && snapshot["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
                %w[binding_event_digest release_event_digest proof_event_digest].all? { |key| cleanup_sha?(snapshot[key]) }
              raise AttemptErrors::ReceiptRejected, "cleanup canonical snapshot differs"
            end
          end
          ids = snapshots.map { |snapshot| snapshot.fetch("mapping_id") }
          raise AttemptErrors::ReceiptRejected, "cleanup canonical snapshots are not uniquely ordered" unless ids == ids.uniq.sort
          removal = receipt.fetch("removal")
          closed_cleanup!(removal, %w[original captured outcome fence_digest])
          unless removal["outcome"] == "removed" && cleanup_sha?(removal["fence_digest"])
            raise AttemptErrors::ReceiptRejected, "cleanup has no positive removal observation"
          end
          %w[original captured].each do |key|
            object = removal.fetch(key)
            closed_cleanup!(object, %w[device inode worktree_admin_id head branch])
            unless %w[device inode].all? { |field| object[field].is_a?(Integer) && object[field].positive? } &&
                object["worktree_admin_id"].is_a?(String) && object["worktree_admin_id"].bytesize.between?(1, 200) &&
                object["worktree_admin_id"].match?(/\A[a-zA-Z0-9_.-]+\z/) &&
                object["head"] == preservation["head"] && object["branch"] == preservation["branch"]
              raise AttemptErrors::ReceiptRejected, "cleanup captured object differs"
            end
          end
          unless removal.fetch("original") == removal.fetch("captured")
            raise AttemptErrors::ReceiptRejected, "cleanup replaced object cannot attest removal"
          end
          true
        end

        def cleanup_sha?(value) = value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
      end
    end
  end
end
