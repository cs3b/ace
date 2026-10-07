# frozen_string_literal: true

require "json"
require "digest"
require "tmpdir"
require "time"
require "ace/assign/authority/client"
require "ace/assign/authority/candidate_transfer"
require "ace/assign/models/execution_receipt"

module Ace
  module Overseer
    module Organisms
      # The original requesting process owns the review through acceptance.
      # Retained files are observation/retry evidence, never an authority cache.
      class ProtectedReview
        def initialize(deployment_loader: nil, kernel: nil, client_factory: nil, reviewer_factory: nil)
          @deployment_loader = deployment_loader || -> { Ace::Assign::Authority::Deployment.load }
          @kernel = kernel || Ace::Runtime::Molecules::ProtectedLinux.new
          @client_factory = client_factory || ->(id, deployment) { Ace::Assign::Authority::Client.new(mapping_id: id, deployment: deployment, kernel: @kernel) }
          @reviewer_factory = reviewer_factory || ->(root) do
            require "ace/review"
            Ace::Review::Organisms::ReviewManager.new(project_root: root)
          end
        end

        def call(project:, agent:, assignment:, attempt:, mutation:, status: false, cancel: false,
          head: nil, candidate_generation: nil, expected_generation: nil, accept_mutation: nil, review_event: nil)
          [project, agent, assignment, attempt, mutation].each { |value| token!(value) }
          raise Error, "Review modes are mutually exclusive" if status && cancel
          if status
            raise Error, "Status forbids mutation and candidate options" if [head, candidate_generation, expected_generation, accept_mutation, review_event].any?
          else
            sha!(head, 40)
            positive!(candidate_generation)
            positive!(expected_generation)
            if cancel
              sha!(review_event, 64)
              raise Error, "Cancel forbids accept mutation" if accept_mutation
            else
              token!(accept_mutation)
              raise Error, "Request and acceptance need distinct mutation IDs" if mutation == accept_mutation
              raise Error, "Request forbids cancellation selector" if review_event
            end
          end
          deployment = @deployment_loader.call
          map = deployment.mapping(agent)
          raise Error, "Mapping belongs to another project" unless map.fetch("project_id") == project
          installed = deployment.project(project)
          peer = @kernel.capture(Process.pid)
          credentials = installed.fetch("peer_credentials").fetch(peer.fetch("uid").to_s)
          unless installed.fetch("reviewer_uids").include?(peer.fetch("uid")) && peer.fetch("uid") != map.fetch("worker_uid") &&
              peer.values_at("gid", "groups") == credentials.values_at("gid", "groups")
            raise Error, "Review requires its installed independent reviewer principal"
          end
          client = @client_factory.call(agent, deployment)
          selectors = {"assignment_id" => assignment, "attempt_id" => attempt}
          return client.call("review_status", selectors.merge("mutation_id" => mutation), timeout: 30).data if status
          candidate = selectors.merge("head" => head, "candidate_generation" => candidate_generation)
          if cancel
            return client.call("cancel_review", candidate.merge("review_event_id" => review_event,
              "expected_generation" => expected_generation), mutation_id: mutation, timeout: 30).data
          end
          root = credentials.fetch("scratch_root")
          Ace::Assign::Authority::PrivateDirectory.verify!(root)
          directory = Dir.mktmpdir("review-request-", root)
          File.chmod(0o700, directory)
          request = candidate.merge("expected_generation" => expected_generation)
          persist(directory, "request.json", JSON.generate("project" => project, "mapping" => agent,
            "request" => request, "mutation" => mutation, "accept_mutation" => accept_mutation, "reviewer" => peer))
          requested = true
          reply = client.call("request_review", request, mutation_id: mutation, timeout: 30)
          persist(directory, "assignment.json", JSON.generate(reply.data))
          if reply.replayed || reply.data["state"] != "assigned"
            return {"state" => reply.data.fetch("state"), "replayed" => reply.replayed,
              "required_action" => "inspect_review_status", "session_dir" => directory}
          end
          review = reply.data.fetch("assignment")
          positive!(reply.data.fetch("generation"))
          unless review.is_a?(Hash) && review.values_at("head", "candidate_generation") == candidate.values_at("head", "candidate_generation") &&
              review["reviewer_uid"] == peer.fetch("uid") && review["reviewer_actor"] == "uid-#{peer.fetch('uid')}" &&
              @kernel.same?(review.fetch("reviewer_process_binding"), peer)
            raise Error, "Assigned review differs from original requesting process or candidate"
          end
          token!(review.fetch("review_id"))
          attempt_state = client.call("attempt_status", selectors.merge("result_candidate_generation" => candidate_generation), timeout: 30).data
          unless attempt_state.values_at("assignment_id", "attempt_id") == [assignment, attempt] &&
              attempt_state["scope"].is_a?(String) && attempt_state["scope"].match?(/\A[0-9]+(?:\.[0-9]+)*\z/)
            raise Error, "Canonical review scope is unavailable"
          end
          purpose = candidate.merge("purpose_id" => review.fetch("review_id"))
          exported = client.call("export_candidate", purpose, download: true, purpose: :candidate, timeout: 30)
          unless exported.parts.is_a?(Array) && exported.parts.size == 1 &&
              exported.data.values_at("head", "candidate_generation") == candidate.values_at("head", "candidate_generation")
            raise Error, "Exported review candidate differs"
          end
          snapshot = Ace::Assign::Authority::CandidateTransfer.new(root: directory).review_snapshot(
            bytes: exported.parts.first, size: exported.data.fetch("bytes"), sha256: exported.data.fetch("sha256"),
            head: head, tree: exported.data.fetch("tree"), root: directory)
          result = @reviewer_factory.call(snapshot.fetch("directory")).execute_prepared_candidate(
            candidate: purpose.merge("tree" => snapshot.fetch("tree")), subject: snapshot.fetch("subject"),
            session_dir: File.join(directory, "execution"))
          unless result[:success] && result[:verdict] == "approved"
            return {"state" => "not_approved", "verdict" => result[:verdict] || "unavailable", "session_dir" => directory}
          end
          artifacts = result.fetch(:artifacts)
          unless artifacts.is_a?(Hash) && artifacts.size.between?(1, 16) && artifacts.all? { |name, bytes|
              name.is_a?(String) && name.match?(/\A[a-zA-Z0-9_.-]{1,128}\z/) && bytes.is_a?(String) && bytes.bytesize.between?(1, 65_536) } &&
              artifacts.values.sum(&:bytesize) <= 256 * 1024
            raise Error, "Review artifacts exceed receipt bounds"
          end
          receipt = Ace::Assign::Models::ExecutionReceipt.new(assignment_id: assignment, attempt_id: attempt,
            project_id: project, scope: attempt_state.fetch("scope"), operation: "review", head: head,
            producer: {"actor" => map.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr"},
            verdict: "succeeded", checks: result.fetch(:checks), recorded_at: Time.now.utc,
            artifacts: artifacts.map { |name, bytes| {"path" => name, "sha256" => Digest::SHA256.hexdigest(bytes)} },
            review: {"head" => head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
          encoded = JSON.generate(receipt.to_h)
          raise Error, "Review receipt exceeds bounds" if encoded.bytesize > 65_536
          persist(directory, "receipt.json", encoded)
          acceptance = purpose.merge("expected_generation" => reply.data.fetch("generation"),
            "receipt_sha256" => Digest::SHA256.hexdigest(encoded))
          persist(directory, "acceptance.json", JSON.generate("mutation" => accept_mutation, "params" => acceptance))
          @kernel.live!(peer)
          unless @kernel.same?(@kernel.capture(Process.pid), review.fetch("reviewer_process_binding"))
            raise Error, "Original reviewer process changed before acceptance"
          end
          accepted = client.call("accept_review", acceptance, mutation_id: accept_mutation,
            upload_parts: [encoded, *artifacts.values], purpose: :receipt_artifacts, timeout: 30)
          unless accepted.data.values_at("head", "candidate_generation", "review_id", "reviewer_uid", "uploaded_receipt_sha256") ==
              [head, candidate_generation, review.fetch("review_id"), peer.fetch("uid"), Digest::SHA256.hexdigest(encoded)]
            raise Error, "Canonical acceptance differs from submitted review"
          end
          persist(directory, "accepted.json", JSON.generate(accepted.data))
          {"state" => "accepted", "acceptance" => accepted.data, "session_dir" => directory}
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError, Error, ArgumentError, KeyError, TypeError, SystemCallError, IOError => error
          raise Error, error.message unless requested
          {"state" => "uncertain", "required_action" => "inspect_review_status", "session_dir" => directory,
            "error" => error.message}
        end

        private

        def persist(directory, name, bytes)
          File.open(File.join(directory, name), File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
            file.write(bytes)
            file.flush
            file.fsync
          end
          File.open(directory, File::RDONLY) { |file| file.fsync }
        end

        def token!(value)
          raise Error, "Review selector is invalid" unless value.is_a?(String) && value.match?(Ace::Assign::Authority::Deployment::TOKEN)
        end

        def positive!(value)
          raise Error, "Review generation must be a positive integer" unless value.is_a?(Integer) && value.positive?
        end

        def sha!(value, length)
          raise Error, "Review digest is invalid" unless value.is_a?(String) && value.match?(/\A[0-9a-f]{#{length}}\z/)
        end
      end
    end
  end
end
