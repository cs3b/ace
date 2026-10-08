# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        # Internal R1 dependency. The fixed authority consumer supplies the
        # original expected linkage; no metadata document can attest execution.
        # Raw imported artifacts are read at this same immutable prefix.
        def with_campaign_execution_evidence!(journal:, commit:, params:, map:, receipt_digest:, execution_binding:)
          raise ArgumentError, "campaign evidence requires a block" unless block_given?
          begin
            row = @launch.completion_terminal!(journal: journal, commit: commit, params: params, map: map)
            unless row["canonical_state"] == "succeeded" && row["reservation_release_event_id"]
              raise AttemptErrors::EvidenceUnavailable, "campaign execution is not succeeded and released"
            end
            definition = @launch.preview_attempt_definition!(journal: journal, commit: commit, params: params, map: map)
            execution = definition.campaign_execution
            raise AttemptErrors::EvidenceUnavailable, "campaign execution linkage is missing" unless execution
            binding = execution.merge(params.slice("assignment_id", "attempt_id"),
              "definition_digest" => row.fetch("definition_digest"), "binding_digest" => row.fetch("original_binding_digest"))
            unless binding == execution_binding && binding["binding_digest"].is_a?(String)
              raise AttemptErrors::EvidenceUnavailable, "campaign execution original linkage differs"
            end
            inventory = journal.canonical_event_inventory!(commit: commit)
            accepted_commit = inventory.fetch("introductions").fetch(params.fetch("assignment_id"))
              .fetch(row.fetch("terminal_event_id"))
            events = @launch.preview_attempt_events!(journal: journal, commit: accepted_commit, params: params, map: map)
            results = events.select { |event| event["type"] == "result_submitted" &&
              event.dig("payload", "receipt_digest") == receipt_digest }
            raise AttemptErrors::EvidenceUnavailable, "campaign execution result is ambiguous" unless results.one?
            submitted = results.first.fetch("payload")
            selected = params.merge(submitted.fetch("binding").slice("head", "candidate_generation"),
              "result_id" => submitted.fetch("result_id"))
            current = exact_candidate!(retained_candidate(events, selected.fetch("candidate_generation")), selected)
            result = verified_result(journal, events, selected, map, retained_origin(events, selected), current, accepted_commit,
              result_id: selected.fetch("result_id"))
            unless result && result["receipt_digest"] == receipt_digest && result.dig("receipt", "verdict") == "succeeded"
              raise AttemptErrors::EvidenceUnavailable, "campaign execution accepted receipt differs"
            end
            terminal = events.find { |event| event["digest"] == row.fetch("terminal_event_id") }
            unless terminal && terminal["type"] == "receipt_accepted" && terminal.dig("payload", "receipt") == result.fetch("receipt")
              raise AttemptErrors::EvidenceUnavailable, "campaign execution terminal receipt differs"
            end
            accepted = approved_review!(journal, events, selected, map, current, commit: accepted_commit)
            campaign_finished_result!(journal: journal, commit: accepted_commit, events: events, params: selected, map: map,
              result: result, accepted: accepted)
            proof = result.fetch("receipt").merge("attempt_id" => params.fetch("attempt_id"),
              "receipt_digest" => receipt_digest, "execution_binding" => binding, "journal_commit" => accepted_commit)
            freeze_campaign_evidence!(proof)
          rescue KeyError, TypeError, ArgumentError, AttemptErrors::ReceiptRejected
            raise AttemptErrors::EvidenceUnavailable, "campaign execution evidence is unavailable"
          end
          active = true
          thread = Thread.current
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          reader = ->(artifact) {
            unless active && Thread.current.equal?(thread) && result.fetch("artifacts").include?(artifact)
              raise AttemptErrors::EvidenceUnavailable, "campaign artifact read escaped its original evidence scope"
            end
            canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
              **result_context(result.fetch("binding")), commit: accepted_commit)
          }
          yield proof, reader
        ensure
          active = false
        end

        private

        def campaign_execution_dependencies!(journal:, commit:, parent_params:, parent_map:)
          # This closure belongs to one held original exclusion and immutable
          # journal selection. Never retained across RPCs. Live/original source
          # parent checks below still run on every callback; only fully verified raw
          # canonical artifacts and their introduced-prefix proof are reused.
          verified = {}
          selected_rows = {}
          inventory = nil
          read = lambda do |reference, phase:, head:, artifacts: nil, name: nil, producer: nil, reviewer: nil, historical: false|
            unless reference.is_a?(Hash) && reference.keys.sort == %w[attempt_id digest] &&
                reference["digest"].is_a?(String) && reference["digest"].match?(DIGEST)
              raise AttemptErrors::EvidenceUnavailable, "campaign child receipt reference differs"
            end
            selection_key = Atoms::EvidenceDigest.digest("commit" => commit, "reference" => reference,
              "phase" => phase, "head" => head, "name" => name)
            params, map, execution, row = selected_rows[selection_key] ||= begin
              inventory ||= journal.canonical_event_inventory!(commit: commit)
              matches = inventory.fetch("events").filter_map do |assignment, events|
                next unless events.any? { |event| event["attempt_id"] == reference["attempt_id"] }
                registration = events.reverse.find { |event| event.dig("payload", "operation") == "register_assignment" }&.dig("payload", "data")
                next unless registration
                descriptor = @launch.send(:control_original_descriptor!, registration.fetch("lifecycle_control"))
                child_map = descriptor.mapping(registration.fetch("mapping_id"))
                params = {"assignment_id" => assignment, "attempt_id" => reference.fetch("attempt_id"),
                  "mapping_id" => registration.fetch("mapping_id")}
                definition = @launch.preview_attempt_definition!(journal: journal, commit: commit, params: params, map: child_map)
                execution = definition.campaign_execution
                next unless execution && execution.values_at("parent_assignment_id", "parent_attempt_id", "phase", "head") ==
                  parent_params.values_at("assignment_id", "attempt_id") + [phase, head]
                next unless child_map["project_id"] == parent_map.fetch("project_id")
                next if name && execution["check_name"] != name
                [params, child_map, execution]
              end
              raise AttemptErrors::EvidenceUnavailable, "campaign child receipt linkage is ambiguous" unless matches.one?
              params, map, execution = matches.first
              row = @launch.completion_terminal!(journal: journal, commit: commit, params: params, map: map)
              [params.freeze, map, freeze_campaign_evidence!(JSON.parse(JSON.generate(execution))),
                freeze_campaign_evidence!(JSON.parse(JSON.generate(row)))]
            end
            binding = execution.merge(params.slice("assignment_id", "attempt_id"),
              "definition_digest" => row.fetch("definition_digest"), "binding_digest" => row.fetch("original_binding_digest"))
            unless historical
              campaign_parent_candidate!(journal: journal, commit: commit, params: parent_params.merge(
                "scope" => execution.fetch("parent_scope"), "head" => head, "base" => execution.fetch("base"),
                "candidate_generation" => execution.fetch("parent_candidate_generation")), map: parent_map)
            end
            key = Atoms::EvidenceDigest.digest("journal" => journal.object_id, "commit" => commit,
              "binding" => binding, "receipt" => reference, "phase" => phase, "head" => head,
              "name" => name, "producer" => producer, "reviewer" => reviewer, "artifacts" => artifacts)
            proof = verified[key] ||= with_campaign_execution_evidence!(journal: journal, commit: commit, params: params, map: map,
              receipt_digest: reference.fetch("digest"), execution_binding: binding) do |canonical, reader|
              canonical.fetch("artifacts").each do |artifact|
                unless Digest::SHA256.hexdigest(reader.call(artifact)) == artifact.fetch("sha256")
                  raise AttemptErrors::EvidenceUnavailable, "canonical campaign artifact bytes differ"
                end
              end
              freeze_campaign_evidence!(JSON.parse(JSON.generate(canonical)))
            end
            if producer && (proof.dig("producer", "actor") != producer || proof.dig("review", "reviewer", "actor") != reviewer)
              raise AttemptErrors::EvidenceUnavailable, "campaign approval original actors differ"
            end
            if artifacts && artifacts.any? { |artifact| !proof.fetch("artifacts").any? { |ref| ref["sha256"] == artifact.fetch("sha256") } }
              raise AttemptErrors::EvidenceUnavailable, "campaign artifact differs from canonical child bytes"
            end
            proof.merge("artifacts" => artifacts || proof.fetch("artifacts"), "historical" => historical)
          end
          {check_evidence: ->(reference, head:, name:, historical: false) {
            read.call(reference, phase: "check", head: head, name: name, historical: historical)
          }, review_evidence: ->(reference, head:, artifacts:, historical: false) {
            read.call(reference, phase: "collection", head: head, artifacts: artifacts, historical: historical)
          }, approval_evidence: ->(reference, head:, artifacts:, producer:, reviewer:, historical: false) {
            read.call(reference, phase: "approval", head: head, artifacts: artifacts, producer: producer, reviewer: reviewer, historical: historical)
          }}.freeze
        end

        def freeze_campaign_evidence!(value)
          case value
          when Hash then value.each { |key, item| freeze_campaign_evidence!(key); freeze_campaign_evidence!(item) }
          when Array then value.each { |item| freeze_campaign_evidence!(item) }
          end
          value.freeze
        end

        # The ordinary result is still campaign-free. Its phase comes only
        # from the authenticated original registered child definition.
        def campaign_child_result!(journal:, commit:, events:, params:, map:, receipt:)
          definition = @launch.preview_attempt_definition!(journal: journal, commit: commit,
            params: params, map: map)
          execution = definition.campaign_execution
          return unless execution
          CampaignExecution.validate!(execution, parent: definition.parent,
            policy: campaign_original_parent_policy!(journal, commit, execution, map))
          intent = events.find { |event| event["type"] == "intent" }&.fetch("payload")
          CampaignExecution.validate_result!(execution, receipt: receipt, base: intent&.fetch("base_head"))
          execution
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::ReceiptRejected, "campaign child result binding is incomplete"
        end

        def campaign_finished_result!(journal:, commit:, events:, params:, map:, result:, accepted:)
          execution = campaign_child_result!(journal: journal, commit: commit, events: events, params: params, map: map,
            receipt: result.fetch("receipt"))
          return unless execution
          CampaignExecution.validate_finished_review!(execution, receipt: result.fetch("receipt"),
            accepted_review: accepted.fetch("review_receipt"))
        rescue KeyError, ArgumentError, TypeError
          raise AttemptErrors::ReceiptRejected, "campaign independent review differs from executed result"
        end

        def campaign_original_parent_policy!(journal, commit, execution, map)
          campaign_original_parent_context!(journal, commit, execution, map).fetch(:selected).fetch("policy")
        end

        def campaign_original_parent_context!(journal, commit, execution, map)
          parent = {"assignment_id" => execution.fetch("parent_assignment_id"),
            "attempt_id" => execution.fetch("parent_attempt_id")}
          inventory = journal.canonical_event_inventory!(commit: commit)
          events = inventory.fetch("events").fetch(parent.fetch("assignment_id"))
          reservations = events.select { |event| event["attempt_id"] == parent.fetch("attempt_id") &&
            event.dig("payload", "operation") == "reserve_attempt" }
          raise AttemptErrors::EvidenceUnavailable, "campaign parent original reservation differs" unless reservations.one?
          parent["mapping_id"] = reservations.first.dig("payload", "data", "mapping_id")
          prefix = inventory.fetch("introductions").fetch(parent.fetch("assignment_id"))
            .fetch(reservations.first.fetch("digest"))
          registration = @launch.send(:definition, journal, parent.fetch("assignment_id"), commit: prefix)
          descriptor = @launch.send(:control_original_descriptor!, registration.fetch("lifecycle_control"))
          original = @launch.send(:control_registration_context!, parent,
            descriptor.mapping(parent.fetch("mapping_id")), journal, commit: commit)
          unless original.fetch(:map).fetch("project_id") == map.fetch("project_id")
            raise AttemptErrors::EvidenceUnavailable, "campaign child original project differs"
          end
          definition = @launch.preview_attempt_definition!(journal: journal, commit: commit,
            params: parent, map: original.fetch(:map))
          selected = CampaignExecution.validate_parent!(definition.review_campaign)
          unless selected.values_at("campaign_id", "subject", "contract_identity") ==
              execution.values_at("campaign_id", "subject", "contract_identity")
            raise AttemptErrors::EvidenceUnavailable, "campaign child original parent differs"
          end
          {params: parent, map: original.fetch(:map), definition: definition, selected: selected}.freeze
        end

        def campaign_prepared_candidate!(journal:, commit:, execution:, map:)
          original = campaign_original_parent_context!(journal, commit, execution, map)
          CampaignExecution.validate!(execution, parent: original.fetch(:definition).id,
            policy: original.fetch(:selected).fetch("policy"))
          params = original.fetch(:params).merge("scope" => execution.fetch("parent_scope"),
            "base" => execution.fetch("base"), "head" => execution.fetch("head"),
            "candidate_generation" => execution.fetch("parent_candidate_generation"))
          campaign_parent_candidate!(journal: journal, commit: commit, params: params, map: original.fetch(:map))
          events = @launch.preview_attempt_events!(journal: journal, commit: commit, params: params, map: original.fetch(:map))
          selected = exact_candidate!(candidate(events), params)
          bytes = journal.bounded_blob(selected.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
          unless bytes.is_a?(String) && bytes.bytesize == selected.fetch("bytes") &&
              Digest::SHA256.hexdigest(bytes) == selected.fetch("sha256")
            raise AttemptErrors::EvidenceUnavailable, "campaign original candidate bundle differs"
          end
          [selected.slice("head", "tree", "bytes", "sha256", "candidate_generation").merge("campaign_execution" => execution), bytes]
        end
      end
    end
  end
end
