# frozen_string_literal: true

require "ace/lab/organisms/protected_service_client"
require_relative "../molecules/protected_selection"

module Ace
  module Overseer
    module Organisms
      class ProtectedPrune
        Preview = Ace::Lab::Atoms::ProtectedWorkspacePrunePreview

        def initialize(selection: nil, document_loader: nil, client_factory: nil, authority_factory: nil)
          @selection = selection || Molecules::ProtectedSelection.new
          @document_loader = document_loader || -> { Ace::Lab::Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path) }
          @client_factory = client_factory || ->(mapping, service, deployment) {
            Ace::Lab::Organisms::ProtectedServiceClient.new(mapping_id: mapping, service_id: service, deployment: deployment)
          }
          @authority_factory = authority_factory || ->(mapping, deployment) {
            Ace::Assign::Authority::Client.new(mapping_id: mapping, deployment: deployment)
          }
        end

        def preview(project:, agent:, assignment:, attempt:, request:)
          intent = Preview.intent!(read_file(request, limit: Preview::Input::MAX_BYTES))
          deployment, service = selection!(intent, project, agent, assignment, attempt)
          @client_factory.call(intent.dig("maintenance", "mapping_id"), service, deployment).preview_workspace_prune(intent: intent)
        rescue ArgumentError, KeyError, TypeError, JSON::ParserError, SystemCallError, IOError, SecurityError,
          Ace::Runtime::RuntimeUnavailableError, Ace::Lab::Error, Ace::Assign::Error => error
          raise Error, "Protected prune preview unavailable (#{error.class.name.split('::').last})"
        end

        def apply(project:, agent:, assignment:, attempt:, request:, mutation:, expected_generation:, authorization:)
          token!(mutation); token!(authorization)
          raise Error, "Expected authority generation must be a positive integer" unless expected_generation.is_a?(Integer) && expected_generation.positive?
          result, intent = result_file!(request)
          deployment, service = selection!(intent, project, agent, assignment, attempt)
          context = result.fetch("maintenance_context")
          input = Preview::Input.parse(JSON.generate({"schema" => "ace.protected-workspace-prune/v1"}.merge(
            result.slice("maintenance", "target", "publication", "preservation"))))
          submission = context.fetch("maintenance").slice("assignment_id", "attempt_id").merge(
            "expected_generation" => expected_generation, "candidate_generation" => context.fetch("candidate_generation"),
            "head" => context.fetch("head"), "request_id" => mutation, "operation" => "prune-preserved-workspace",
            "authorization" => authorization, "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input),
            "target" => Ace::Lab::Atoms::ServiceInput.target(input))
          @client_factory.call(context.dig("maintenance", "mapping_id"), service, deployment).submit(
            submission: submission, input_bytes: JSON.generate(input), mutation_id: mutation)
        rescue ArgumentError, KeyError, TypeError, JSON::ParserError, SystemCallError, IOError, SecurityError,
          Ace::Runtime::RuntimeUnavailableError, Ace::Lab::Error, Ace::Assign::Error => error
          raise Error, "Protected prune apply unavailable (#{error.class.name.split('::').last})"
        end

        def status(request:, mutation:)
          token!(mutation)
          result, intent = result_file!(request)
          target = intent.fetch("target")
          deployment, = selection!(intent, *target.values_at("project_id", "mapping_id", "assignment_id", "attempt_id"))
          context = result.fetch("maintenance_context")
          params = context.fetch("maintenance").slice("assignment_id", "attempt_id").merge(
            "head" => context.fetch("head"), "candidate_generation" => context.fetch("candidate_generation"), "request_id" => mutation)
          @authority_factory.call(context.dig("maintenance", "mapping_id"), deployment).call(
            "service_status", params, mutation_id: nil, timeout: 5).data
        rescue ArgumentError, KeyError, TypeError, JSON::ParserError, SystemCallError, IOError, SecurityError,
          Ace::Runtime::RuntimeUnavailableError, Ace::Lab::Error, Ace::Assign::Error => error
          raise Error, "Protected prune status unavailable (#{error.class.name.split('::').last})"
        end

        private

        def result_file!(path)
          result = read_file(path, limit: 16_384)
          intent = Preview.intent!({"schema" => "ace.protected-workspace-prune-preview/v1",
            "maintenance" => result.fetch("maintenance"), "target" => result.fetch("target").except("artifact_digest"),
            "publication" => result.fetch("publication"), "destinations" => result.fetch("preservation").fetch("destinations")})
          context = Preview.context!(result.fetch("maintenance_context"))
          raise Error, "Preview maintenance context differs" unless context.fetch("maintenance") == intent.fetch("maintenance")
          [Preview.result!(result, intent: intent, context: context), intent]
        end

        def token!(value)
          raise Error, "Explicit protected service identity is required" unless value.is_a?(String) && value.match?(Preview::Input::ID)
        end

        def selection!(intent, project, agent, assignment, attempt)
          unless intent.fetch("target").values_at("project_id", "mapping_id", "assignment_id", "attempt_id") ==
              [project, agent, assignment, attempt]
            raise Error, "Protected prune target differs from CLI selection"
          end
          maintenance = intent.fetch("maintenance")
          # The successor can omit the retired target mapping. Visibility and
          # current caller admission belong to the separate maintenance actor.
          deployment, = @selection.call(project: maintenance.fetch("project_id"), agent: maintenance.fetch("mapping_id"))
          map = deployment.mapping(maintenance.fetch("mapping_id"))
          raise Error, "Protected maintenance project differs" unless map.fetch("project_id") == maintenance.fetch("project_id")
          operation = @document_loader.call.fetch("operations").fetch("prune-preserved-workspace")
          service = operation.fetch("service_id")
          unless operation.fetch("project") == maintenance.fetch("project_id") &&
              deployment.project(maintenance.fetch("project_id")).fetch("service_receivers").key?(service)
            raise Error, "Installed protected prune receiver is unavailable"
          end
          [deployment, service]
        end

        def read_file(path, limit:)
          raise ArgumentError, "request FILE is required" unless path.is_a?(String) && !path.empty?
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            raise ArgumentError, "request FILE must be bounded and regular" unless file.stat.file? && file.stat.size.between?(1, limit)
            bytes = file.read(limit + 1).force_encoding(Encoding::UTF_8)
            raise ArgumentError, "request FILE must be bounded UTF-8" unless bytes.bytesize.between?(1, limit) && bytes.valid_encoding?
            JSON.parse(bytes, create_additions: false, max_nesting: 16, allow_nan: false,
              allow_comments: false, allow_duplicate_key: false)
          end
        end
      end
    end
  end
end
