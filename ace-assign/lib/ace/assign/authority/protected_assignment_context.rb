# frozen_string_literal: true

require_relative "deployment_history"
require_relative "prepared_input"
require_relative "prepared_queue"

module Ace
  module Assign
    module Authority
      # Installed and retained deployment owners determine protected principals.
      # A removed original mapping never silently restores ordinary local mode.
      class ProtectedAssignmentContext
        def self.load
          paths = [Deployment::PATH, DeploymentHistory::PATH]
          installed = paths.any? do |path|
            begin
              File.lstat(path)
              true
            rescue Errno::ENOENT
              false
            end
          end
          return new(deployment: nil, history: nil) unless installed
          deployment = Deployment.load
          history = DeploymentHistory.load
          unless history.selects?(deployment)
            raise AttemptErrors::EvidenceUnavailable, "installed protected descriptor is not retained"
          end
          new(deployment: deployment, history: history)
        end

        def initialize(deployment:, history:, uid: Process.uid, kernel: nil, env: ENV)
          @deployment, @history, @uid, @kernel, @env = deployment, history, uid, kernel, env
        end

        def protected_worker?
          return false unless @deployment
          [@deployment, *@history.descriptors].any? do |owner|
            owner.data.fetch("projects").values.any? { |project| project.fetch("worker_uids").include?(@uid) }
          end
        end

        def resolve(options:, assignment_id:, scope:)
          selected = options.values_at(:mapping, :attempt).any? { |value| value && !value.to_s.empty? } ||
            %w[ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_ATTEMPT_ID].any? { |key| !@env[key].to_s.empty? }
          return nil unless protected_worker? || selected
          unless @deployment && assignment_id && scope && scope.match?(PreparedWork::SCOPE)
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: explicit scoped assignment required"
          end
          mapping = selected_hint(options[:mapping], "ACE_ASSIGN_LAUNCH_MAPPING")
          attempt = selected_hint(options[:attempt], "ACE_ASSIGN_ATTEMPT_ID")
          hint = @env["ACE_ASSIGN_ASSIGNMENT_ID"].to_s
          unless hint.empty? || hint == assignment_id
            raise AttemptErrors::EvidenceUnavailable, "prepared assignment hint differs"
          end
          @kernel ||= Ace::Runtime::Molecules::ProtectedLinux.new
          input = PreparedInput.fetch(client: Client.new(mapping_id: mapping, deployment: @deployment, kernel: @kernel),
            assignment_id: assignment_id, attempt_id: attempt)
          unless input.descriptor.fetch("scope") == scope
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_mismatch: scoped CLI selection"
          end
          input
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: original installed mapping is unavailable"
        end

        private

        def selected_hint(explicit, key)
          hint = @env[key].to_s
          value = explicit || hint
          unless value.is_a?(String) && value.match?(PreparedWork::TOKEN) && (hint.empty? || hint == value)
            raise AttemptErrors::EvidenceUnavailable, "prepared selector hint differs"
          end
          value
        end
      end

      # Each supported operation holds the existing private queue exclusion and
      # consumes its authenticated held snapshot. No graph-changing API exists.
      class PreparedExecutor
        def initialize(input)
          @queue = PreparedQueue.new(work: input.work, descriptor: input.descriptor)
          @scope = input.descriptor.fetch("scope")
        end

        def status
          @queue.with_executor(&:status)
        end

        %i[start_step finish_step fail].each do |operation|
          define_method(operation) do |*args, **options|
            unless options[:fork_root] == @scope && (!options[:step_number] ||
                options[:step_number] == @scope || options[:step_number].start_with?(@scope + "."))
              raise AttemptErrors::EvidenceUnavailable, "prepared operation scope differs"
            end
            @queue.with_executor { |executor| executor.public_send(operation, *args, **options) }
          end
        end

        def method_missing(*)
          raise AttemptErrors::EvidenceUnavailable, "prepared queue graph changes require a reviewed new prepared version and attempt"
        end

        def respond_to_missing?(*); false; end
      end
    end
  end
end
