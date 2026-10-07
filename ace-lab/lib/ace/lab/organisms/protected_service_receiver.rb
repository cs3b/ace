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
          handler: Molecules::ProtectedServiceHandler.new, cleanup_owner: nil)
          @mapping_id, @service_id, @deployment, @kernel, @handler = mapping_id, service_id, deployment, kernel, handler
          @cleanup_owner = cleanup_owner
          @map = deployment.mapping(mapping_id)
          deployment.verify_composition!(@map.fetch("authority_id"), composition: "services")
          @project = deployment.project(@map.fetch("project_id"))
          @receiver = @project.fetch("service_receivers").fetch(service_id)
          @client = client || Ace::Assign::Authority::Client.new(mapping_id: mapping_id, deployment: deployment, kernel: kernel)
          @inputs = Molecules::ProtectedServicePolicy.new(proposal_resolver: ->(*) { raise SecurityError, "proposal decisions belong to authority" })
        end

        def execute(submission:, peer:, input_bytes:, mutation_id:, on_claim: nil, claim_timeout: nil)
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
          if claim_timeout && (!claim_timeout.is_a?(Numeric) || !claim_timeout.finite? ||
              !claim_timeout.positive? || claim_timeout > 5)
            raise ArgumentError, "receiver claim deadline is invalid"
          end
          bytes = input_bytes.dup.freeze
          mutation_id = mutation_id.dup.freeze
          input = @inputs.input_binding(bytes, expected_digest: params.fetch("input_digest"),
            expected_target: params.fetch("target"), operation: params.fetch("operation"))
          cleanup = params.fetch("operation") == "prune-preserved-workspace"
          raise SecurityError, "fixed cleanup owner composition is unavailable" if cleanup && !@cleanup_owner
          contacted = true
          claim_options = {mutation_id: mutation_id, upload_parts: [bytes], purpose: :service_input}
          claim_options[:timeout] = claim_timeout if claim_timeout
          claim = @client.call("request_service", params, **claim_options)
          notify_claim(on_claim, claim, request_id) if on_claim
          unless !claim.replayed && claim.data["claim"] == "created"
            return projection(claim.data)
          end
          original_cleanup_owner = @cleanup_owner.identity! if cleanup
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
          if cleanup && Ace::Assign::Atoms::EvidenceDigest.digest(original_cleanup_owner) !=
              Ace::Assign::Atoms::EvidenceDigest.digest(started.data.fetch("operation_owner_binding"))
            raise SecurityError, "original cleanup admission owner differs"
          end

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
          if cleanup
            artifacts = cleanup_result_evidence!(params, input.fetch(:input), claim.data, started.data)
            response = {"outcome" => "succeeded", "evidence" => artifacts.each_with_index.map do |artifact, index|
              {"ref" => "cleanup-#{index}", "sha256" => Digest::SHA256.hexdigest(artifact)}
            end}
          else
            response = @handler.execute(operation: immutable(operation), envelope: envelope, candidate_root: materialized.fetch("directory"))
            return uncertain(params.fetch("request_id")) unless response
            artifacts = Ace::Assign::Authority::EvidenceTransfer.read_staged(root: materialized.fetch("directory"), evidence: response.fetch("evidence"))
          end
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
          SecurityError, ArgumentError, KeyError, SystemCallError, Timeout::Error
          contacted ? uncertain(request_id) : {"request_id" => request_id, "state" => "refused", "code" => "invalid_receiver_admission"}
        end

        private

        def cleanup_result_evidence!(params, input, claim, started)
          owner = started.fetch("operation_owner_binding")
          result = @cleanup_owner.execute!(request: {
            "request_id" => params.fetch("request_id"), "input_digest" => params.fetch("input_digest"),
            "claim_binding" => claim.fetch("claim_binding"), "request_event_digest" => claim.fetch("request_event_digest"),
            "dispatch_event_digest" => started.fetch("dispatch_event_digest"), "input" => input
          }, operation_owner_binding: owner)
          selection = {"schema" => "ace.protected-workspace-prune-root-selection/v1",
            "request_id" => params.fetch("request_id"), "input_digest" => params.fetch("input_digest"),
            "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(owner),
            "receipt_ref" => result.fetch(:receipt_ref)}
          [result.fetch(:bytes), JSON.generate(selection)]
        end

        # A source-owned listener callback, never a wire-selected handler. Its
        # reply exposes accepted canonical identity before long work. Transport
        # loss in the callback is handled by that listener; it cannot resend.
        def notify_claim(callback, claim, request_id)
          data = claim.data
          unless data.is_a?(Hash) && data["request_id"] == request_id &&
              data["generation"].is_a?(Integer) && data["generation"].positive? &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              [true, false].include?(claim.replayed)
            raise SecurityError, "canonical service acceptance identity is unavailable"
          end
          callback.call(immutable(data.slice("request_id", "generation", "journal_commit", "state", "claim")
            .merge("replayed" => claim.replayed)))
        end

        def cleanup_staging(directory, identity, prefix: "candidate-")
          quarantine = nil
          root = File.expand_path(@receiver.fetch("staging_root"))
          Ace::Assign::Authority::PrivateDirectory.verify!(root)
          current = File.lstat(directory)
          return unless File.dirname(directory) == root && File.basename(directory).start_with?(prefix) &&
            current.directory? && current.uid == Process.uid && current.dev == identity.dev && current.ino == identity.ino
          # Capture the pathname atomically before checking the object we will
          # delete. A concurrent replacement at the original name must survive.
          quarantine = Dir.mktmpdir(".receiver-cleanup-", root)
          File.chmod(0o700, quarantine)
          captured = File.join(quarantine, "candidate")
          File.rename(directory, captured)
          moved = File.lstat(captured)
          return unless moved.directory? && moved.uid == Process.uid &&
            moved.dev == identity.dev && moved.ino == identity.ino
          FileUtils.remove_entry_secure(captured)
        rescue Ace::Assign::Error, SystemCallError
          # A cleanup failure cannot change already-confirmed canonical truth.
          # Never fall back to cleaning the staging root or another directory.
          nil
        ensure
          if quarantine
            begin
              # Never recursively remove a mismatched captured object.
              Dir.rmdir(quarantine)
            rescue SystemCallError
              nil
            end
          end
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

require_relative "protected_service_recovery"
