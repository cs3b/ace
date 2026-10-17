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
        attr_reader :descriptor, :work, :working_directory

        def self.fetch(client:, assignment_id:, attempt_id:)
          reply = client.call("evidence_fetch", {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "kind" => "prepared_work", "purpose_id" => "original_prepared_work", "artifact_id" => "prepared_bundle"},
            download: true, purpose: :candidate, timeout: 30)
          new(reply: reply, candidate_loader: -> {
            client.call("evidence_fetch", {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
              "kind" => "campaign_candidate", "purpose_id" => "original_campaign_candidate", "artifact_id" => "candidate_bundle"},
              download: true, purpose: :candidate, timeout: 30)
          })
        end

        def initialize(reply:, candidate_reply: nil, candidate_loader: nil)
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
          execution = work.definition["campaign_execution"]
          if execution
            candidate_reply ||= candidate_loader&.call
            candidate = candidate_reply&.data&.fetch("descriptor")
            unless candidate.is_a?(Hash) && candidate.keys.sort == %w[head tree bytes sha256 candidate_generation campaign_execution mapping_id assignment_id attempt_id project_id original_worker_identity original_worker_scratch_root original_binding_digest].sort &&
                candidate.slice("mapping_id", "assignment_id", "attempt_id", "project_id", "original_worker_identity", "original_worker_scratch_root", "original_binding_digest") ==
                  descriptor.slice("mapping_id", "assignment_id", "attempt_id", "project_id", "original_worker_identity", "original_worker_scratch_root", "original_binding_digest") &&
                candidate.fetch("campaign_execution") == execution && candidate.fetch("head") == execution.fetch("head") &&
                candidate.fetch("candidate_generation") == execution.fetch("parent_candidate_generation") &&
                candidate_reply.parts.is_a?(Array) && candidate_reply.parts.one?
              raise AttemptErrors::EvidenceUnavailable, "campaign original candidate input differs"
            end
            materialized = CandidateTransfer.new(root: root).materialize_repository(bytes: candidate_reply.parts.first,
              sha256: candidate.fetch("sha256"), size: candidate.fetch("bytes"), head: candidate.fetch("head"),
              tree: candidate.fetch("tree"), root: root)
            @working_directory = materialized.fetch("directory").freeze
          elsif candidate_reply
            raise AttemptErrors::EvidenceUnavailable, "ordinary prepared input forbids a campaign candidate"
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
          if (execution = work.definition["campaign_execution"])
            instructions << "This is a registered campaign #{execution.fetch('phase')} child. The provider working directory is the private authenticated parent candidate repository at #{Shellwords.escape(execution.fetch('head'))}, with original base #{Shellwords.escape(execution.fetch('base'))}. Do not edit or advance that candidate. Execute the captured #{Shellwords.escape(execution.fetch('operation'))} phase and retain its actual #{Shellwords.escape(execution.fetch('check_name'))} check and report artifacts. Submit an ordinary campaign-free result (campaign null), operation #{Shellwords.escape(execution.fetch('operation'))}, exact original head/base, and actual check outcome. The existing independent reviewer must validate those same artifact bytes; an approval child must retain the exact canonical independent review actor/verdict. No session metadata or completed queue step counts as a settled R1 campaign round."
          end
          original = "--mapping #{Shellwords.escape(descriptor.fetch('mapping_id'))} --assignment #{Shellwords.escape(descriptor.fetch('assignment_id'))} --attempt #{Shellwords.escape(descriptor.fetch('attempt_id'))}"
          instructions << "Record executed tests and independent review evidence for the exact candidate head in the assignment reports. The local attempt receipt #{original} is the delivery record; never invent successful checks, treat a written report as proof, or convert queue completion into a receipt."

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
