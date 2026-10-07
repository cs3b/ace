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
          rendered = text.gsub(/\{\{([^{}]*)\}\}/) do
            token = Regexp.last_match(1)
            field = token.delete_prefix("admitted.")
            unless token == "admitted." + field && values.key?(field)
              raise AttemptErrors::EvidenceUnavailable, "prepared_input_invalid: unknown instruction token"
            end
            Shellwords.escape(values.fetch(field))
          end
          if rendered.include?("{{") || rendered.include?("}}")
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_invalid: unresolved instruction token"
          end
          rendered.freeze
        end

        def drive_prompt
          target = Shellwords.escape(descriptor.fetch("assignment_id") + "@" + descriptor.fetch("scope"))
          selectors = "--assignment #{target} --mapping #{Shellwords.escape(descriptor.fetch('mapping_id'))} --attempt #{Shellwords.escape(descriptor.fetch('attempt_id'))}"
          instructions = ["Drive the authenticated captured assignment subtree. Use ace-assign status #{selectors}, step #{selectors}, start #{selectors}, finish #{selectors} --message REPORT, and fail #{selectors} --message REASON. Do not fork-run, add, retry, renumber, or expand another graph."]
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
