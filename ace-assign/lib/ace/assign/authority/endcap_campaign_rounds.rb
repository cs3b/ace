# frozen_string_literal: true
require_relative "campaign_round_transfer"

module Ace
  module Assign
    module Authority
      class Endcap
        private

        def campaign_round_request!(request)
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch("campaign_record_round").sort &&
              params["head"].is_a?(String) && params["head"].match?(CandidateTransfer::SHA) &&
              params["candidate_generation"].is_a?(Integer) && params["candidate_generation"].positive? &&
              params["input_sha256"].is_a?(String) && params["input_sha256"].match?(DIGEST)
            raise ArgumentError, "campaign round request differs"
          end
          %w[mapping_id assignment_id attempt_id].each { |key| result_id!(params.fetch(key)) }
          result_id!(request.fetch("mutation_id"))
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "campaign project differs" unless map["project_id"] == request.fetch("project_id")
          [params, map]
        end

        def authorize_campaign_round!(request:, peer:, role:)
          params, map = campaign_round_request!(request)
          @launch.with_assignment(params: params, map: map) do |journal, registration|
            protected_journal!(journal)
            descriptor = @launch.send(:control_original_descriptor!, registration.fetch("lifecycle_control"))
            original_map = descriptor.mapping(params.fetch("mapping_id"))
            events = @launch.preview_attempt_events!(journal: journal, commit: journal.ref_value, params: params, map: original_map)
            finish_identity!(events, params, original_map, peer, role)
            definition = @launch.preview_attempt_definition!(journal: journal, commit: journal.ref_value, params: params, map: original_map)
            CampaignExecution.validate_parent!(definition.review_campaign)
          end
          true
        end

        def with_campaign_receipt!(journal:, commit:, events:, params:, map:, receipt:, result:, historical:)
          unless result.is_a?(Hash) && result["schema"] == "ace.review.accepted-result/v1" &&
              receipt["campaign"].is_a?(Hash) && receipt["campaign"].keys.sort == %w[id result] &&
              receipt["operation"] == "review" && receipt["verdict"] == "succeeded"
            raise AttemptErrors::ReceiptRejected, "parent campaign receipt differs"
          end
          context = @launch.send(:control_registration_context!, params, map, journal, commit: commit)
          original_map = context.fetch(:map)
          descriptor = context.fetch(:descriptor)
          selected = CampaignExecution.validate_parent!(@launch.preview_attempt_definition!(journal: journal,
            commit: commit, params: params, map: original_map).review_campaign)
          unless receipt.dig("campaign", "id") == selected.fetch("campaign_id") && result["campaign_id"] == selected.fetch("campaign_id")
            raise AttemptErrors::ReceiptRejected, "parent campaign identity differs"
          end
          origin = retained_origin(events, params)
          parent = params.merge("scope" => origin.fetch("scope"), "base" => origin.fetch("base_head"), "head" => receipt.fetch("head"))
          current = exact_candidate!(retained_candidate(events, params.fetch("candidate_generation")), parent)
          project = descriptor.project(original_map.fetch("project_id"))
          root = File.join(project.fetch("campaign_repository"), ".ace-local", "review", "candidate-views")
          FileUtils.mkdir_p(root, mode: 0o700)
          bundle = journal.bounded_blob(current.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
          CandidateTransfer.new(root: root).with_campaign_repository(bytes: bundle, sha256: current.fetch("sha256"),
            size: current.fetch("bytes"), head: current.fetch("head"), tree: current.fetch("tree"), base: parent.fetch("base")) do |candidate_reader|
            manager = @launch.send(:campaign_manager_for!, context,
              **campaign_execution_dependencies!(journal: journal, commit: commit, parent_params: parent, parent_map: original_map),
              candidate_reader: candidate_reader)
            binding = selected.slice("subject", "contract_identity", "policy").transform_keys(&:to_sym).merge(
              result: result, head: receipt.fetch("head"), base: parent.fetch("base"),
              producer: receipt.fetch("producer").fetch("actor"), reviewer: receipt.fetch("review").fetch("reviewer").fetch("actor"))
            if historical
              manager.verify_retained_result!(**binding)
              yield
            else
              deployment_sha = @launch.send(:protected_descriptor_sha256!)
              CampaignConsumerPolicy.new.with(@deployment.project(original_map.fetch("project_id")).fetch("campaign_policy")) do |profiles, held|
                manager.with_verified_result!(**binding, consumer_profiles: profiles) do |verified|
                  unless result == manager.accepted_result_snapshot(selected.fetch("campaign_id"))
                    raise AttemptErrors::ReceiptRejected, "exported campaign result bytes differ from verified owner"
                  end
                  held.verify_unchanged!
                  campaign_parent_candidate!(journal: journal, commit: commit, params: parent, map: original_map)
                  unless @launch.send(:protected_descriptor_sha256!) == deployment_sha
                    raise AttemptErrors::Conflict, "campaign consumer policy descriptor advanced"
                  end
                  value = yield
                  held.verify_unchanged!
                  unless @launch.send(:protected_descriptor_sha256!) == deployment_sha
                    raise AttemptErrors::Conflict, "campaign consumer policy descriptor advanced"
                  end
                  value
                end
              end
            end
          end
        rescue Ace::Review::Atoms::CampaignContract::Invalid, KeyError, TypeError, ArgumentError
          raise AttemptErrors::ReceiptRejected, "canonical parent campaign evidence is unavailable"
        end

        def with_campaign_submission!(journal:, commit:, events:, params:, map:, admitted:, replay:)
          receipt = admitted.fetch(:receipt)
          return yield unless receipt["campaign"]
          definition = @launch.preview_attempt_definition!(journal: journal, commit: commit, params: params, map: map)
          unless definition.review_campaign
            raise AttemptErrors::EvidenceUnavailable, "protected campaigns require their canonical owner"
          end
          reference = receipt.fetch("campaign").fetch("result")
          index = receipt.fetch("artifacts").index(reference)
          raise AttemptErrors::ReceiptRejected, "campaign result is not an uploaded artifact" unless index
          result = JSON.parse(admitted.fetch(:artifacts).fetch(index), create_additions: false,
            max_nesting: 64, allow_duplicate_key: false, allow_comments: false)
          with_campaign_receipt!(journal: journal, commit: commit, events: events, params: params, map: map,
            receipt: receipt, result: result, historical: !replay.nil?) { yield }
        rescue JSON::ParserError
          raise AttemptErrors::ReceiptRejected, "campaign result JSON is malformed"
        end

        # Service callers already retain with_assignment's original control SH
        # and authority mutex through CAS. Round writers take the same keys EX
        # before R1, so this read cannot invert with an admitted round writer.
        def campaign_service_checks!(journal:, commit:, events:, params:, map:, current:)
          definition = @launch.preview_attempt_definition!(journal: journal, commit: commit, params: params, map: map)
          return true unless definition.review_campaign
          parent = params.merge("head" => current.fetch("head"), "candidate_generation" => current.fetch("candidate_generation"))
          result = verified_result(journal, events, parent, map, retained_origin(events, parent), current, commit)
          unless result&.dig("receipt", "campaign") && result.dig("receipt", "verdict") == "succeeded"
            raise AttemptErrors::ReceiptRejected, "ready or merge requires its canonical parent campaign result and executed checks"
          end
          with_campaign_finish!(journal: journal, commit: commit, events: events,
            params: parent.merge("result_id" => result.fetch("result_id")), map: map) { true }
        end

        def with_campaign_finish!(journal:, commit:, events:, params:, map:)
          record = events.find { |event| event["type"] == "result_submitted" && event.dig("payload", "result_id") == params["result_id"] }
          return yield unless record&.dig("payload", "receipt", "campaign")
          current = exact_candidate!(candidate(events), params)
          payload = verified_result(journal, events, params, map, retained_origin(events, params), current, commit,
            result_id: params.fetch("result_id"))
          reference = payload.fetch("receipt").fetch("campaign").fetch("result")
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          bytes = canonical.read({"ref" => reference.fetch("path"), "sha256" => reference.fetch("sha256")},
            **result_context(payload.fetch("binding")), commit: commit)
          result = JSON.parse(bytes, create_additions: false, max_nesting: 64, allow_duplicate_key: false, allow_comments: false)
          with_campaign_receipt!(journal: journal, commit: commit, events: events, params: params, map: map,
            receipt: payload.fetch("receipt"), result: result, historical: false) { yield }
        rescue JSON::ParserError
          raise AttemptErrors::ReceiptRejected, "canonical campaign result JSON is malformed"
        end

        def dispatch_campaign_export(request:, peer:, role:, body: true)
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch("campaign_export_result").sort &&
              params["head"].is_a?(String) && params["head"].match?(CandidateTransfer::SHA) &&
              params["candidate_generation"].is_a?(Integer) && params["candidate_generation"].positive? && request["mutation_id"].nil?
            raise ArgumentError, "campaign result selectors differ"
          end
          %w[mapping_id assignment_id attempt_id].each { |key| result_id!(params.fetch(key)) }
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "campaign project differs" unless map["project_id"] == request.fetch("project_id")
          @launch.with_assignment(params: params, map: map, exclusive: true) do |journal, registration|
            protected_journal!(journal)
            commit = journal.ref_value
            descriptor = @launch.send(:control_original_descriptor!, registration.fetch("lifecycle_control"))
            original_map = descriptor.mapping(params.fetch("mapping_id"))
            context = @launch.send(:control_registration_context!, params, original_map, journal, commit: commit)
            events = @launch.preview_attempt_events!(journal: journal, commit: commit, params: params, map: original_map)
            origin = active_origin(events, params)
            role == :worker ? worker_or_launcher!(peer, role, original_map, origin) : finish_identity!(events, params, original_map, peer, role)
            selected = CampaignExecution.validate_parent!(@launch.preview_attempt_definition!(journal: journal,
              commit: commit, params: params, map: original_map).review_campaign)
            return true unless body
            parent = params.merge("scope" => origin.fetch("scope"), "base" => origin.fetch("base_head"))
            campaign_parent_candidate!(journal: journal, commit: commit, params: parent, map: original_map)
            current = exact_candidate!(candidate(events), params)
            bundle = journal.bounded_blob(current.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
            project = descriptor.project(original_map.fetch("project_id"))
            root = File.join(project.fetch("campaign_repository"), ".ace-local", "review", "candidate-views")
            FileUtils.mkdir_p(root, mode: 0o700)
            CandidateTransfer.new(root: root).with_campaign_repository(bytes: bundle, sha256: current.fetch("sha256"),
              size: current.fetch("bytes"), head: current.fetch("head"), tree: current.fetch("tree"), base: parent.fetch("base")) do |candidate_reader|
              manager = @launch.send(:campaign_manager_for!, context,
                **campaign_execution_dependencies!(journal: journal, commit: commit, parent_params: parent, parent_map: original_map),
                candidate_reader: candidate_reader)
              result = manager.accepted_result_snapshot(selected.fetch("campaign_id"))
              deployment_sha = @launch.send(:protected_descriptor_sha256!)
              CampaignConsumerPolicy.new.with(@deployment.project(original_map.fetch("project_id")).fetch("campaign_policy")) do |profiles, held|
              manager.with_verified_result!(result: result, **selected.slice("subject", "contract_identity", "policy").transform_keys(&:to_sym),
                head: params.fetch("head"), base: parent.fetch("base"), producer: result.fetch("producer"), reviewer: result.fetch("reviewer"),
                consumer_profiles: profiles) do
                held.verify_unchanged!
                unless @launch.send(:protected_descriptor_sha256!) == deployment_sha
                  raise AttemptErrors::Conflict, "campaign export policy descriptor advanced"
                end
                campaign_parent_candidate!(journal: journal, commit: commit, params: parent, map: original_map)
                bytes = JSON.generate(result).b
                raise AttemptErrors::EvidenceUnavailable, "campaign result exceeds artifact bound" if bytes.bytesize > 64 * 1024
                {data: {"campaign_id" => selected.fetch("campaign_id"), "result_identity" => result.fetch("result_identity"),
                  "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize, "head" => params.fetch("head"),
                  "candidate_generation" => params.fetch("candidate_generation"), "journal_commit" => commit},
                  replayed: false, transfer_parts: [bytes]}
              end
              end
            end
          end
        rescue Ace::Review::Atoms::CampaignContract::Invalid, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "canonical campaign result is unavailable"
        end

        def dispatch_campaign_round(request:, peer:, role:, transfer:)
          params, map = campaign_round_request!(request)
          admitted = CampaignRoundTransfer.decode(input: transfer, sha256: params.fetch("input_sha256"))
          input = admitted.fetch(:round)
          unless input["attempt_id"] == request.fetch("mutation_id") && input["head"] == params.fetch("head")
            raise AttemptErrors::Conflict, "campaign round stable request or head differs"
          end
          @launch.with_assignment(params: params, map: map, exclusive: true) do |journal, registration|
            protected_journal!(journal)
            commit = journal.ref_value
            descriptor = @launch.send(:control_original_descriptor!, registration.fetch("lifecycle_control"))
            original_map = descriptor.mapping(params.fetch("mapping_id"))
            context = @launch.send(:control_registration_context!, params, original_map, journal, commit: commit)
            events = @launch.preview_attempt_events!(journal: journal, commit: commit, params: params, map: original_map)
            origin = finish_identity!(events, params, original_map, peer, role)
            selected = CampaignExecution.validate_parent!(@launch.preview_attempt_definition!(journal: journal,
              commit: commit, params: params, map: original_map).review_campaign)
            parent_params = params.merge("scope" => origin.fetch("scope"), "base" => input.fetch("base"))
            project = descriptor.project(original_map.fetch("project_id"))
            paths = CampaignRoundTransfer.materialize(admitted: admitted, repository: project.fetch("campaign_repository"),
              request_id: request.fetch("mutation_id"))
            dependencies = campaign_execution_dependencies!(journal: journal, commit: commit,
              parent_params: parent_params, parent_map: original_map)
            current = exact_candidate!(retained_candidate(events, params.fetch("candidate_generation")), params)
            bundle = journal.bounded_blob(current.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
            quarantine = File.join(project.fetch("campaign_repository"), ".ace-local", "review", "candidate-views")
            FileUtils.mkdir_p(quarantine, mode: 0o700)
            transfer_owner = CandidateTransfer.new(root: quarantine)
            transfer_owner.with_campaign_repository(bytes: bundle, sha256: current.fetch("sha256"), size: current.fetch("bytes"),
              head: current.fetch("head"), tree: current.fetch("tree"), base: input.fetch("base")) do |candidate_reader|
              manager = @launch.send(:campaign_manager_for!, context, **dependencies, artifact_paths: paths, candidate_reader: candidate_reader)
              deployment_sha = @launch.send(:protected_descriptor_sha256!)
              CampaignConsumerPolicy.new.with(@deployment.project(original_map.fetch("project_id")).fetch("campaign_policy")) do |profiles, held|
                # The existing R1 store checks exact replay before fresh policy,
                # and binds the complete supplied frame in its input_digest.
                data = manager.record_round(selected.fetch("campaign_id"), input, source_digest: admitted.fetch(:sha256),
                  expected_campaign: selected.reject { |key, _| key == "version" }, consumer_profiles: profiles,
                  before_record: -> {
                    held.verify_unchanged!
                    campaign_parent_candidate!(journal: journal, commit: commit, params: parent_params, map: original_map)
                    unless @launch.send(:protected_descriptor_sha256!) == deployment_sha
                      raise AttemptErrors::Conflict, "campaign policy descriptor advanced"
                    end
                  })
                held.verify_unchanged!
                unless journal.ref_value == commit && @launch.send(:protected_descriptor_sha256!) == deployment_sha
                  raise AttemptErrors::Conflict, "campaign round canonical selection advanced"
                end
                reply = data.slice("campaign_id", "recorded_complete", "completed_rounds", "accepted", "result_identity", "replayed")
                  .merge("request_id" => request.fetch("mutation_id"), "round_id" => input.fetch("round_id"))
                {data: reply, replayed: data["replayed"] == true}
              end
            end
          end
        rescue Ace::Review::Atoms::CampaignContract::Invalid, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "canonical campaign round is unavailable"
        end
      end
    end
  end
end
