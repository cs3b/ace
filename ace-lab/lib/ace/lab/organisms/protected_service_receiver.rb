# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"
require "ace/assign/authority/client"
require "ace/assign/authority/candidate_transfer"
require "ace/assign/authority/evidence_transfer"
require_relative "../molecules/protected_service_handler"
require_relative "../molecules/protected_service_policy"

module Ace
  module Lab
    module Organisms
      # Fixed executor-side orchestration. All durable permission and outcome
      # state remains in the existing authority journal. Transport supplies
      # the kernel peer; submitted actor strings are never accepted.
      class ProtectedServiceReceiver
        SUBMISSION = %w[assignment_id attempt_id expected_generation candidate_generation head request_id
          operation input_digest target authorization].freeze

        def initialize(mapping_id:, service_id:, deployment: Ace::Assign::Authority::Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, client: nil,
          handler: Molecules::ProtectedServiceHandler.new)
          @mapping_id, @service_id, @deployment, @kernel, @handler = mapping_id, service_id, deployment, kernel, handler
          @map = deployment.mapping(mapping_id)
          deployment.verify_composition!(@map.fetch("authority_id"), composition: "services")
          @project = deployment.project(@map.fetch("project_id"))
          @receiver = @project.fetch("service_receivers").fetch(service_id)
          @client = client || Ace::Assign::Authority::Client.new(mapping_id: mapping_id, deployment: deployment, kernel: kernel)
          @inputs = Molecules::ProtectedServicePolicy.new(proposal_resolver: ->(*) { raise SecurityError, "proposal decisions belong to authority" })
        end

        def execute(submission:, peer:, input_bytes:, mutation_id:)
          contacted = false
          request_id = nil
          unless submission.is_a?(Hash) && submission.keys.sort == SUBMISSION.sort &&
              peer.fetch("uid") == @map.fetch("worker_uid") && peer["gid"] == @map.fetch("worker_gid") &&
              peer["groups"] == @map.fetch("worker_groups")
            raise SecurityError, "receiver submission or peer differs"
          end
          params = immutable(submission.merge("service_id" => @service_id, "worker_process_binding" => peer))
          id = params.fetch("request_id")
          unless id.is_a?(String) && id.match?(Ace::Assign::Molecules::JournalMutation::ID)
            raise ArgumentError, "receiver request identity is invalid"
          end
          request_id = id
          peer = params.fetch("worker_process_binding")
          @kernel.live!(peer)
          me = @kernel.capture(Process.pid)
          credentials = @project.fetch("peer_credentials").fetch(@receiver.fetch("executor_uid").to_s)
          unless me["uid"] == @receiver["executor_uid"] && me["gid"] == credentials["gid"] && me["groups"] == credentials["groups"]
            raise SecurityError, "receiver principal differs"
          end
          unless input_bytes.is_a?(String) && mutation_id.is_a?(String) && mutation_id.match?(Ace::Assign::Molecules::JournalMutation::ID)
            raise ArgumentError, "receiver input or mutation identity is invalid"
          end
          bytes = input_bytes.dup.freeze
          input = @inputs.input_binding(bytes, expected_digest: params.fetch("input_digest"), expected_target: params.fetch("target"))
          contacted = true
          claim = @client.call("request_service", params, mutation_id: mutation_id, upload_parts: [bytes], purpose: :service_input)
          unless !claim.replayed && claim.data["claim"] == "created"
            return projection(claim.data)
          end
          binding = params.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
          exported = @client.call("export_candidate", binding.except("request_id").merge("purpose_id" => params.fetch("request_id")),
            download: true, purpose: :candidate, timeout: 30)
          unless exported.parts.is_a?(Array) && exported.parts.length == 1
            raise SecurityError, "candidate export is incomplete"
          end
          materialized = Ace::Assign::Authority::CandidateTransfer.new(root: @receiver.fetch("staging_root")).materialize(
            bytes: exported.parts.first, sha256: exported.data.fetch("sha256"), size: exported.data.fetch("bytes"),
            head: binding.fetch("head"), tree: exported.data.fetch("tree"), root: @receiver.fetch("staging_root"))
          staging_identity = File.lstat(materialized.fetch("directory"))
          begin_params = binding.merge("claim_binding" => claim.data.fetch("claim_binding"), "expected_generation" => claim.data.fetch("generation"))
          started = @client.call("begin_dispatch", begin_params, mutation_id: Digest::SHA256.hexdigest("begin:#{mutation_id}"), upload_parts: [bytes], purpose: :service_input)
          return projection(started.data) unless !started.replayed && started.data["invocation"] == "permitted"

          document = Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path)
          operation = Molecules::ServicePolicy.new(document).operation!(params.fetch("operation"),
            project: @map.fetch("project_id"), service_id: @service_id)
          authorization = @client.call("service_authorization", binding.merge("claim_binding" => claim.data.fetch("claim_binding"),
            "input_digest" => params.fetch("input_digest")), upload_parts: [bytes], purpose: :service_input)
          expected = binding.slice("head", "candidate_generation", "request_id").merge("claim_binding" => claim.data.fetch("claim_binding"),
            "policy_digest" => claim.data.fetch("policy_digest"), "operation_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(operation))
          unless !authorization.replayed && authorization.data == expected
            raise SecurityError, "current authority authorization differs"
          end
          # This successful fresh authority read is the admission point. A
          # later veto cannot retroactively undo it; no read creates permission.
          reloaded = Molecules::ServicePolicy.new(Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path)).operation!(
            params.fetch("operation"), project: @map.fetch("project_id"), service_id: @service_id)
          unless Ace::Assign::Atoms::EvidenceDigest.digest(reloaded) == expected.fetch("operation_digest")
            raise SecurityError, "local operation changed after admission"
          end
          canonical = params.slice(*Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS, "authorization", "service_id").merge(
            "project_id" => @map.fetch("project_id"), "candidate_head" => binding.fetch("head"),
            "caller_uid" => peer.fetch("uid"), "executor_uid" => @receiver.fetch("executor_uid"), "transport" => "unix")
          envelope = immutable("version" => 1, "request" => canonical, "input" => input.fetch(:input), "execution" => {
            "executor_uid" => @receiver.fetch("executor_uid"), "authority_id" => @map.fetch("authority_id"),
            "claim_binding" => claim.data.fetch("claim_binding"), "candidate_generation" => binding.fetch("candidate_generation"),
            "head" => binding.fetch("head"), "staging_id" => File.basename(materialized.fetch("directory"))})
          response = @handler.execute(operation: immutable(operation), envelope: envelope, candidate_root: materialized.fetch("directory"))
          return uncertain(params.fetch("request_id")) unless response
          artifacts = Ace::Assign::Authority::EvidenceTransfer.read_staged(root: materialized.fetch("directory"), evidence: response.fetch("evidence"))
          receipt = canonical.slice(*Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge(
            "outcome" => response.fetch("outcome"), "evidence" => response.fetch("evidence"))
          receipt_bytes = JSON.generate(receipt)
          completion = @client.call("complete_service", binding.merge("claim_binding" => claim.data.fetch("claim_binding"),
            "receipt_sha256" => Digest::SHA256.hexdigest(receipt_bytes)),
            mutation_id: Digest::SHA256.hexdigest("complete:#{mutation_id}"), upload_parts: [receipt_bytes] + artifacts, purpose: :receipt_artifacts)
          unless completion.data["request_id"] == request_id && %w[succeeded failed].include?(completion.data["state"])
            return uncertain(request_id)
          end
          cleanup_staging(materialized.fetch("directory"), staging_identity)
          projection(completion.data)
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError, Ace::Lab::InvalidConfigurationError,
          SecurityError, ArgumentError, KeyError, SystemCallError
          contacted ? uncertain(request_id) : {"request_id" => request_id, "state" => "refused", "code" => "invalid_receiver_admission"}
        end

        private

        def cleanup_staging(directory, identity)
          root = File.expand_path(@receiver.fetch("staging_root"))
          Ace::Assign::Authority::PrivateDirectory.verify!(root)
          current = File.lstat(directory)
          return unless File.dirname(directory) == root && File.basename(directory).start_with?("candidate-") &&
            current.directory? && current.uid == Process.uid && current.dev == identity.dev && current.ino == identity.ino
          # Only this invocation's privately materialized directory is removed,
          # after the authority durably accepted its exact terminal receipt.
          FileUtils.remove_entry_secure(directory)
        rescue Ace::Assign::Error, SystemCallError
          # A cleanup failure cannot change already-confirmed canonical truth.
          # Never fall back to cleaning the staging root or another directory.
          nil
        end

        def projection(data)
          data.slice("request_id", "state", "dispatch_phase", "claim", "generation", "journal_commit")
        end

        def uncertain(id)
          {"request_id" => id, "state" => "uncertain", "required_action" => "inspect_canonical_service_status_and_record_exact_outcome"}
        end

        def immutable(value)
          copy = JSON.parse(JSON.generate(value))
          freeze_value(copy)
        end

        def freeze_value(value)
          value.each_value { |child| freeze_value(child) } if value.is_a?(Hash)
          value.each { |child| freeze_value(child) } if value.is_a?(Array)
          value.freeze
        end
      end
    end
  end
end
