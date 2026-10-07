# frozen_string_literal: true
require "ace/assign/authority/client"
require_relative "../molecules/protected_selection"
require_relative "protected_status"

module Ace
  module Overseer
    module Organisms
      # Visibility and exact inventory select a target, never a replay grant.
      # The authority authenticates the original principal and immutable input.
      class ProtectedSteering
        def initialize(selection: nil, status: nil, client_factory: nil)
          @selection = selection || Molecules::ProtectedSelection.new
          @status = status || ProtectedStatus.new
          @client_factory = client_factory || ->(id, deployment) { Ace::Assign::Authority::Client.new(mapping_id: id, deployment: deployment) }
        end

        def prompt(project:, agent:, assignment:, attempt:, mutation:, expected_generation: nil, text: nil, status: false)
          if status
            raise Error, "Prompt status forbids text and expected generation" unless text.nil? && expected_generation.nil?
          else
            generation!(expected_generation)
            unless text.is_a?(String) &&
                text.dup.force_encoding(Encoding::UTF_8).valid_encoding? && text.bytesize.between?(1, 16_384) &&
                !text.dup.force_encoding(Encoding::UTF_8).match?(/\A[[:space:]]*\z/)
              raise Error, "Prompt must be bounded UTF-8 non-whitespace text"
            end
          end
          client, selectors = target(project, agent, assignment, attempt, mutation)
          if status
            client.call("prompt_status", selectors.merge("mutation_id" => mutation), mutation_id: nil, timeout: 30).data
          else
            client.call("prompt_attempt", selectors.merge("expected_generation" => expected_generation),
              mutation_id: mutation, upload_parts: [text], purpose: :prompt_text, timeout: 30).data
          end
        end

        def stop(project:, agent:, assignment:, attempt:, mutation:, expected_generation:)
          generation!(expected_generation)
          client, selectors = target(project, agent, assignment, attempt, mutation)
          client.call("stop_attempt", selectors.merge("expected_generation" => expected_generation), mutation_id: mutation).data
        end

        private

        def target(project, agent, assignment, attempt, mutation)
          [project, agent, assignment, attempt, mutation].each do |value|
            unless value.is_a?(String) && value.match?(Ace::Assign::Authority::Deployment::TOKEN)
              raise Error, "Exact protected steering identity is required"
            end
          end
          deployment, = @selection.call(project: project, agent: agent)
          snapshot = @status.collect(project: project, agent: agent)
          selected = snapshot.fetch("agents").select { |entry| entry["agent_id"] == agent }
          unless snapshot["project_id"] == project && selected.size == 1 && selected.first["status"] == "ok"
            raise Error, "Exact protected steering inventory is unavailable"
          end
          rows = selected.first.fetch("inventory").fetch("items").select do |row|
            row.values_at("assignment_id", "attempt_id") == [assignment, attempt]
          end
          unless rows.size == 1 && rows.first["original_binding_digest"].is_a?(String) &&
              rows.first["original_binding_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise Error, "Exact original protected steering binding is unavailable"
          end
          # Do not compare the supplied generation with current inventory:
          # an identical explicit replay retains its earlier immutable generation.
          [@client_factory.call(agent, deployment), {"assignment_id" => assignment, "attempt_id" => attempt}]
        rescue KeyError, TypeError, NoMethodError
          raise Error, "Protected steering inventory is malformed"
        end

        def generation!(value)
          raise Error, "Observed generation must be a positive integer" unless value.is_a?(Integer) && value.positive?
        end
      end
    end
  end
end
