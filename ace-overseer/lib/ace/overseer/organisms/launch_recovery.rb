# frozen_string_literal: true

require_relative "../molecules/launch_request"
require_relative "protected_status"

module Ace
  module Overseer
    module Organisms
      # Canonical discovery only. Missing input or missing attribution never
      # authorizes replacement, registration, upload, cleanup or a new launch.
      class LaunchRecovery
        def initialize(status: nil, request_factory: nil)
          @status = status || ProtectedStatus.new
          @request_factory = request_factory || ->(root) { Molecules::LaunchRequest.new(root: root) }
        end

        def call(path:)
          path = File.expand_path(path)
          owner = @request_factory.call(File.dirname(path))
          request = owner.load(path)
          availability = owner.bundle_availability(request)
          definition_availability = owner.definition_availability(request)
          snapshot = @status.collect(project: request.fetch("project_id"), agent: request.fetch("mapping_id"))
          mapping = snapshot.fetch("agents").find { |entry| entry.fetch("agent_id") == request.fetch("mapping_id") }
          raise Error, "Retained invocation canonical inventory is unavailable" unless mapping && mapping.fetch("status") == "ok"
          inventory = mapping.fetch("inventory")
          reference = JSON.parse(request.fetch("definition_bytes")).fetch("prepared_work")
          bundle = request.fetch("prepared_bundle")
          matches = inventory.fetch("items").select do |row|
            row.fetch("reservation_mutation_id") == request.fetch("mutation_id") + "-reserve"
          end
          raise Error, "Retained invocation reservation is ambiguous" if matches.size > 1
          row = matches.first
          if row
            expected = {"assignment_id" => request.fetch("assignment_id"), "task_id" => request.fetch("task_id"),
              "scope" => request.fetch("scope"), "base_head" => request.fetch("base_head"),
              "definition_digest" => request.fetch("definition_sha256"), "selection_sha256" => reference.fetch("selection_sha256"),
              "prepared_bundle_bytes" => bundle.fetch("bytes"), "prepared_bundle_sha256" => bundle.fetch("sha256"),
              "prepared_bundle_ref" => "execution/prepared/#{request.fetch('assignment_id')}-#{bundle.fetch('sha256')}.bundle"}
            raise Error, "Retained invocation differs from original reservation" unless expected.all? { |key, value| row.fetch(key) == value }
          end
          {"request_path" => path, "project_id" => request.fetch("project_id"), "mapping_id" => request.fetch("mapping_id"),
            "assignment_id" => request.fetch("assignment_id"), "mutation_id" => request.fetch("mutation_id"),
            "definition_sha256" => request.fetch("definition_sha256"), "selection_sha256" => reference.fetch("selection_sha256"),
            "prepared_bundle" => bundle, "local_bundle" => availability, "local_definition" => definition_availability,
            "attribution" => row ? "original_reservation" : "unattributed", "journal_commit" => inventory.fetch("journal_commit"), "item" => row}
        rescue KeyError, TypeError, JSON::ParserError
          raise Error, "Retained invocation recovery metadata is malformed"
        end
      end
    end
  end
end
