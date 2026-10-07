# frozen_string_literal: true

module Ace
  module Assign
    # Fresh operation-specific inspection is a named controlled domain seam.
    # Challenge selection, transfer, import and acceptance use actual owners.
    module ServiceNoEffectOwnerFixture
      def start_service_server
        @kernel.peer_identity = @executor
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| Ace::Assign::EndcapResultOwnerFixture::WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        client_kernel = Ace::Assign::EndcapResultOwnerFixture::Kernel.new
        client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
      end

      def no_effect_upload(record, challenge)
        inspection = challenge.fetch("payload").slice("request_id", "input_digest", "claim_binding",
          "no_effect_challenge", "challenge_generation", "failure_event_digest", "failure_generation").merge(
            "version" => 1, "challenge_event_digest" => challenge.fetch("digest"), "target" => record.fetch("target"),
            "dispatch_phase" => record.fetch("dispatch_phase"), "effect_absent" => true,
            "handler_terminated" => true, "writers_absent" => true)
        evidence = "ace-service-attestation request:service-request input:#{record.fetch("input_digest")} outcome:failed no-effect:true\n" +
          "ace-service-no-effect #{JSON.generate(inspection)}\n"
        receipt = record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "failed",
          "evidence" => [{"ref" => "executor-inspection", "sha256" => Digest::SHA256.hexdigest(evidence)}])
        bytes = JSON.generate(receipt)
        parts = [bytes, evidence]
        params = {"head" => @head, "candidate_generation" => 1, "request_id" => "service-request",
          "claim_binding" => record.fetch("claim_binding"),
          "reconciliation_challenge" => record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"),
          "receipt_sha256" => Digest::SHA256.hexdigest(bytes),
          "transfer" => Authority::TransferCodec.new(root: @root).descriptor(parts, purpose: :receipt_artifacts)}
        [params, self.class::Parts.new(parts)]
      end

    end
  end
end
