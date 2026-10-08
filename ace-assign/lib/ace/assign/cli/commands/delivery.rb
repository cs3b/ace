# frozen_string_literal: true
require "json"
require_relative "../../authority/protected_assignment_context"
require_relative "../../organisms/protected_delivery_coordinator"

module Ace
  module Assign
    module CLI
      module Commands
        class Delivery < Ace::Support::Cli::Command
          desc "Execute or reconcile attempt-bound forge delivery"
          option :assignment, required: true, desc: "Managed assignment ID"
          option :attempt, required: true, desc: "Active delivery attempt ID"
          option :operation, required: true, desc: "create, update, ready, review, merge, status"
          option :parameters, desc: "JSON delivery parameters (otherwise assignment source delivery mapping)"
          option :title, desc: "PR title"
          option :body_file, desc: "PR description file"
          option :tests, desc: "JSON reference to coordinator-accepted test attempt and receipt digest"
          option :review, desc: "JSON reference to coordinator-accepted independent review attempt and receipt digest"
          option :service_request, desc: "Completed authorized qjx merge request ID (merge consumption only)"
          option :mapping, desc: "Installed original protected mapping selector"
          option :scope, desc: "Original prepared worker scope"
          option :candidate_head, desc: "Exact original protected candidate SHA"
          option :candidate_generation, type: :integer, desc: "Exact original protected candidate generation"
          option :input_digest, desc: "Exact original accepted merge input SHA256"
          option :target, desc: "Exact original merge PR URL"
          option :artifact_digest, desc: "Original target artifact SHA256, if present"

          def initialize(protected_context: nil)
            @protected_assignment_context = protected_context
          end

          def call(**options)
            context = @protected_assignment_context ||= Ace::Assign::Authority::ProtectedAssignmentContext.load
            protected = context.protected_participant? || options[:mapping] || context.mapping_hint?
            if protected
              unless context.protected_worker?
                raise AttemptErrors::EvidenceUnavailable, "protected delivery is worker-only"
              end
              unless %w[merge status].include?(options[:operation]) && %i[title body_file tests review].all? { |key| options[key].nil? }
                raise ArgumentError, "protected delivery accepts canonical merge/status only; local input/evidence flags are unavailable"
              end
              input = context.resolve(options: options, assignment_id: options[:assignment], scope: options[:scope])
              raise AttemptErrors::EvidenceUnavailable, "original protected prepared input is unavailable" unless input
              result = Organisms::ProtectedDeliveryCoordinator.new(client: context.client(options: options),
                project_id: input.work.manifest.fetch("project_id")).perform(assignment_id: options[:assignment],
                  attempt_id: options[:attempt], operation: options[:operation], service_request_id: options[:service_request],
                  candidate_head: options[:candidate_head], candidate_generation: options[:candidate_generation],
                  input_digest: options[:input_digest], target: {"resource" => options[:target], "artifact_digest" => options[:artifact_digest]},
                  parameters: read_json(options[:parameters]))
              puts JSON.generate(json_value(result))
              return
            end
            if %i[mapping scope candidate_head candidate_generation input_digest target artifact_digest].any? { |key| options[key] }
              raise ArgumentError, "protected delivery selectors cannot select ordinary local delivery"
            end
            result = build_delivery.perform(assignment_id: options[:assignment], attempt_id: options[:attempt],
              operation: options[:operation], parameters: read_json(options[:parameters]),
              title: options[:title], body: options[:body_file] && File.read(options[:body_file]),
              tests: read_json(options[:tests]), review: read_json(options[:review]),
              service_request_id: options[:service_request])
            puts JSON.generate(json_value(result))
          rescue ArgumentError, Ace::Git::Error, Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError,
            JSON::ParserError, SecurityError, SystemCallError => e
            message = e.is_a?(JSON::ParserError) ? "protected installed selection unavailable" : e.message
            raise Ace::Support::Cli::Error, message
          end

          private

          def build_delivery
            Organisms::DeliveryCoordinator.new(repo_root: Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current)
          end

          def read_json(path)
            return nil unless path
            bytes = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
              before = file.stat
              raise ArgumentError, "Delivery input must be a bounded regular file" unless before.file? && before.size <= 65_536
              value = file.read(65_537)
              after = file.stat
              unless value && value.bytesize <= 65_536 &&
                  [before.dev, before.ino, before.size, before.mtime, before.ctime] == [after.dev, after.ino, after.size, after.mtime, after.ctime]
                raise ArgumentError, "Delivery input changed or exceeds its bound"
              end
              value
            end
            data = JSON.parse(bytes, max_nesting: 16, create_additions: false,
              allow_duplicate_key: false, allow_comments: false, allow_nan: false)
            raise ArgumentError, "Delivery input must be a JSON object" unless data.is_a?(Hash)
            data
          rescue JSON::ParserError
            raise ArgumentError, "Delivery input must be valid JSON"
          end

          def json_value(value)
            case value
            when Hash then value.transform_values { |item| json_value(item) }
            when Array then value.map { |item| json_value(item) }
            else value.respond_to?(:to_h) ? json_value(value.to_h) : value
            end
          end
        end
      end
    end
  end
end
