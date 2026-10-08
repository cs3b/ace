# frozen_string_literal: true

require "shellwords"
require_relative "client"
require_relative "prepared_work"

module Ace
  module Assign
    module Authority
      # One authenticated original fetch and one immutable verified work graph.
      # Caller identifiers select; the maintained Client/Endcap authenticates.
      class PreparedInput
        attr_reader :descriptor, :work

        def self.fetch(client:, assignment_id:, attempt_id:)
          reply = client.call("evidence_fetch", {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "kind" => "prepared_work", "purpose_id" => "original_prepared_work", "artifact_id" => "prepared_bundle"},
            download: true, purpose: :candidate, timeout: 30)
          new(reply: reply)
        end

        def initialize(reply:)
          @descriptor = reply.data.fetch("descriptor")
          Molecules::LifecycleExclusion.workspace_reader(projection: descriptor.fetch("workspace_exclusion"))
          unless descriptor.dig("workspace_exclusion", "root_resource", "view_path") ==
              "/run/ace/lifecycle-exclusion/#{descriptor.fetch('mapping_id')}"
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: original lifecycle mapping differs"
          end
          unless reply.parts.is_a?(Array) && reply.parts.one?
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: one original bundle required"
          end
          root = PrivateDirectory.verify!(descriptor.fetch("original_worker_scratch_root"))
          @work = PreparedWork.admit(bytes: reply.parts.first, head: descriptor.fetch("prepared_head"),
            tree: descriptor.fetch("prepared_tree"), sha256: descriptor.fetch("sha256"), size: descriptor.fetch("bytes"), root: root)
          expected = work.reference(head: descriptor.fetch("prepared_head"), tree: descriptor.fetch("prepared_tree"))
          definition = work.definition_bytes(head: descriptor.fetch("prepared_head"), tree: descriptor.fetch("prepared_tree"))
          unless expected == descriptor.slice(*expected.keys) &&
              descriptor.values_at("assignment_id", "project_id") == work.manifest.values_at("assignment_id", "project_id") &&
              Digest::SHA256.hexdigest(definition) == descriptor.fetch("definition_digest")
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_mismatch: original graph association"
          end
          @descriptor = JSON.parse(JSON.generate(descriptor))
          pending = [@descriptor]
          until pending.empty?
            value = pending.pop
            pending.concat(value.values) if value.is_a?(Hash)
            pending.concat(value) if value.is_a?(Array)
            value.freeze
          end
          freeze
        end

        def render(text)
          values = descriptor.slice("mapping_id", "assignment_id", "scope", "attempt_id")
          rendered = +""
          cursor = 0
          # Only an opening delimiter introduces a token. Closing braces in
          # literal JSON are preserved; inserted selector values are not parsed.
          while (opening = text.index("{{", cursor))
            rendered << text[cursor...opening]
            closing = text.index("}}", opening + 2)
            unless closing
              raise AttemptErrors::EvidenceUnavailable, "prepared_input_invalid: unresolved instruction token"
            end
            token = text[(opening + 2)...closing]
            if token.include?("{") || token.include?("}")
              raise AttemptErrors::EvidenceUnavailable, "prepared_input_invalid: unresolved instruction token"
            end
            field = token.delete_prefix("admitted.")
            unless token == "admitted." + field && values.key?(field)
              raise AttemptErrors::EvidenceUnavailable, "prepared_input_invalid: unknown instruction token"
            end
            rendered << Shellwords.escape(values.fetch(field))
            cursor = closing + 2
          end
          rendered << text[cursor..]
          rendered.freeze
        end

        def drive_prompt
          target = Shellwords.escape(descriptor.fetch("assignment_id") + "@" + descriptor.fetch("scope"))
          selectors = "--assignment #{target} --mapping #{Shellwords.escape(descriptor.fetch('mapping_id'))} --attempt #{Shellwords.escape(descriptor.fetch('attempt_id'))}"
          instructions = ["Drive the authenticated captured assignment subtree. Use ace-assign status #{selectors}, step #{selectors}, start #{selectors}, finish #{selectors} --message REPORT, and fail #{selectors} --message REASON. Do not fork-run, add, retry, renumber, or expand another graph."]
          original = "--mapping #{Shellwords.escape(descriptor.fetch('mapping_id'))} --assignment #{Shellwords.escape(descriptor.fetch('assignment_id'))} --attempt #{Shellwords.escape(descriptor.fetch('attempt_id'))}"
          instructions << "Before the original worker exits, explicitly submit its tested candidate and real execution result through the protected authority. Queue completion is not candidate/result acceptance. Read ace-assign authority status #{original}; persist its authority_generation with the complete next command arguments and ordered byte inputs. For each NEW operation use a new explicit mutation and a newly selected generation; for exact retries preserve the original generation, mutation and bytes."
          instructions << "Submit one prepared Git bundle: ace-assign submit-candidate #{original} --head HEAD --candidate-generation CURRENT_CANDIDATE --expected-generation G --mutation CANDIDATE_MUTATION --bundle FILE. Select CURRENT_CANDIDATE from status result_candidate_generation, using 0 when null. Persist the returned candidate_generation and head as REVIEWED_CANDIDATE and HEAD; never derive the next counter by arithmetic or from queue completion."
          instructions << "Have an independent installed reviewer run ace-overseer review --project #{Shellwords.escape(descriptor.fetch('project_id'))} --agent #{Shellwords.escape(descriptor.fetch('mapping_id'))} --assignment #{Shellwords.escape(descriptor.fetch('assignment_id'))} --attempt #{Shellwords.escape(descriptor.fetch('attempt_id'))} --head HEAD --candidate-generation REVIEWED_CANDIDATE --expected-generation G --mutation REVIEW_REQUEST --accept-mutation REVIEW_ACCEPT. Do not impersonate that principal. The review consumer owns actual candidate export, independent checks and canonical acceptance. After review, read authority status again before the first result submission."
          instructions << "Produce the real receipt with Ace::Assign::Models::ExecutionReceipt.new/to_h: original assignment/attempt/project and scope #{Shellwords.escape(descriptor.fetch('scope'))}, exact tested candidate head, installed worker actor/role worker/runtime herdr, actual operation/verdict/executed checks and ordered artifact path/SHA256 pairs. No invented successful check or queue-to-receipt conversion. Submit JSON bytes and matching ordered artifact files with ace-assign submit-result #{original} --head HEAD --candidate-generation REVIEWED_CANDIDATE --expected-generation G --mutation RESULT_MUTATION --receipt FILE --artifact FILE ... . Failed empty artifacts use no --artifact; succeeded requires evidence. Supervisor finish is separate and revalidates result, independent review and no-writer/settlement proof."
          instructions << "For an authorized merge step captured INSIDE this subtree, use the protected delivery rule in wfi://assign/drive. Never execute an outer preset step or expand this graph. Retain the exact approved candidate, structured input bytes, authorization and request ID before the first request; select authority_generation for that new request only."
          service = "--project #{Shellwords.escape(descriptor.fetch('project_id'))} #{original} --scope #{Shellwords.escape(descriptor.fetch('scope'))} --candidate-head HEAD --candidate-generation REVIEWED_CANDIDATE"
          instructions << "Request the uniquely installed authorized merge receiver: ace-lab service request #{service} --service SERVICE --operation merge --authorization AUTHORIZATION --request-id REQUEST --expected-generation G --input INPUT_FILE. Credentials alone are not authorization. Persist the returned original input_digest and target with all request arguments. Lost/uncertain replies never permit another effect or refreshed-generation retry."
          instructions << "Inspect the same request: ace-lab service status #{service} --request REQUEST --input-digest INPUT_DIGEST --target TARGET. Only canonical succeeded evidence permits ace-assign delivery #{original} --scope #{Shellwords.escape(descriptor.fetch('scope'))} --operation merge --service-request REQUEST --candidate-head HEAD --candidate-generation REVIEWED_CANDIDATE --input-digest INPUT_DIGEST --target TARGET. This consumption verifies the imported receipt and never executes merge. Refusal, unavailable or uncertain leaves the active delivery step unfinished; report its exact blocker. Finish the queue step only after succeeded canonical delivery."
          work.manifest.fetch("context").each do |entry|
            instructions << render(work.files.fetch(entry.fetch("text").fetch("filename")))
          end
          work.manifest.fetch("steps").each do |entry|
            instructions << "Step #{entry.fetch('number')}:\n" + render(work.parse_queue_step!(work.files.fetch("steps/" + entry.fetch("filename"))).fetch(:body))
          end
          instructions.join("\n\n").freeze
        end
      end
    end
  end
end
