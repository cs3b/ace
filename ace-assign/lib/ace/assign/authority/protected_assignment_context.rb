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
        attr_reader :uid

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

        def initialize(deployment:, history:, uid: Process.uid, kernel: nil, env: ENV,
          artifacts_factory: -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new })
          @deployment, @history, @uid, @kernel, @env = deployment, history, uid, kernel, env
          @artifacts_factory = artifacts_factory
        end

        # A declared installed account never falls through to local authority.
        # This is classification only; each wire operation still authenticates
        # the current kernel peer and its exact permitted role.
        def protected_participant?
          return false unless @deployment
          raise AttemptErrors::EvidenceUnavailable, "protected retained owners are unavailable" unless @history
          [@deployment, *@history.descriptors].any? do |owner|
            data = owner.data
            principals = data.fetch("authorities").values.map { |authority| authority.fetch("uid") }
            principals.concat(data.fetch("launch_mappings").values.flat_map { |map| map.values_at("launcher_uid", "worker_uid") })
            data.fetch("projects").each_value do |project|
              %w[launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids].each do |key|
                principals.concat(project.fetch(key, []))
              end
              principals.concat(project.fetch("service_receivers", {}).values.map { |receiver| receiver.fetch("executor_uid") })
              principals.concat(project.fetch("inbox_contexts", {}).values.map { |context| context.fetch("owner_credentials").fetch("uid") })
            end
            principals.include?(@uid)
          end
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "protected installed principal inventory is malformed"
        end

        # Read-only current selection; no role grant or private Inbox access.
        def inbox_context_selection(project:, mapping:, inbox_context:)
          unless installed? && [project, mapping, inbox_context].all? { |id| id.is_a?(String) && Deployment::TOKEN.match?(id) }
            raise AttemptErrors::EvidenceUnavailable, "installed inbox selectors differ"
          end
          descriptor = @deployment.artifact_reference
          history = @history.artifact_reference
          unless descriptor && history && @history.selects?(@deployment)
            raise AttemptErrors::EvidenceUnavailable, "installed inbox references are unavailable"
          end
          @artifacts_factory.call.with do |held|
            held.read!(descriptor)
            held.read!(history)
            map = @deployment.mapping(mapping)
            unless map.fetch("project_id") == project
              raise AttemptErrors::EvidenceUnavailable, "installed inbox project differs"
            end
            selected = @deployment.inbox_context(mapping, inbox_context)
            authority = @deployment.authority(map.fetch("authority_id"))
            result = {"uid" => @uid, "project_id" => project, "mapping_id" => mapping,
              "inbox_context_id" => inbox_context, "descriptor" => descriptor, "history" => history,
              "context" => selected.slice("control_socket_path", "owner_credentials", "native_mapping_id"),
              "authority" => authority.slice("socket_path", "uid", "gid", "groups")
                .merge("authority_id" => map.fetch("authority_id"))}
            held.verify_unchanged!
            value = yield result
            held.verify_unchanged!
            value
          end
        rescue ArgumentError, KeyError, TypeError, Ace::Runtime::Error
          raise AttemptErrors::EvidenceUnavailable, "installed inbox selection is unavailable"
        end

        def protected_worker?
          return false unless @deployment
          [@deployment, *@history.descriptors].any? do |owner|
            owner.data.fetch("projects").values.any? { |project| project.fetch("worker_uids").include?(@uid) }
          end
        end

        def installed?
          !@deployment.nil? && !@history.nil?
        end

        def refuse_graph_mutation!(options:)
          selected = options.values_at(:mapping, :attempt).any? { |value| value && !value.to_s.empty? } ||
            %w[ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_ATTEMPT_ID].any? { |key| !@env[key].to_s.empty? }
          if protected_worker? || selected
            raise AttemptErrors::EvidenceUnavailable, "protected queue graph changes require a reviewed new prepared version and attempt"
          end
        end

        def resolve(options:, assignment_id:, scope:)
          selected = options.values_at(:mapping, :attempt).any? { |value| value && !value.to_s.empty? } ||
            %w[ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_ATTEMPT_ID].any? { |key| !@env[key].to_s.empty? }
          return nil unless protected_worker? || selected
          unless @deployment && assignment_id && scope && scope.match?(PreparedWork::SCOPE)
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: explicit scoped assignment required"
          end
          attempt = selected_hint(options[:attempt], "ACE_ASSIGN_ATTEMPT_ID")
          hint = @env["ACE_ASSIGN_ASSIGNMENT_ID"].to_s
          unless hint.empty? || hint == assignment_id
            raise AttemptErrors::EvidenceUnavailable, "prepared assignment hint differs"
          end
          @kernel ||= Ace::Runtime::Molecules::ProtectedLinux.new
          input = PreparedInput.fetch(client: client(options: options),
            assignment_id: assignment_id, attempt_id: attempt)
          unless input.descriptor.fetch("scope") == scope
            raise AttemptErrors::EvidenceUnavailable, "prepared_input_mismatch: scoped CLI selection"
          end
          input
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: original installed mapping is unavailable"
        end

        def verify_attempt_hints!(assignment_id:, attempt_id:)
          selected_hint(assignment_id, "ACE_ASSIGN_ASSIGNMENT_ID")
          selected_hint(attempt_id, "ACE_ASSIGN_ATTEMPT_ID")
          true
        end

        def client(options:)
          raise AttemptErrors::EvidenceUnavailable, "protected installed authority is unavailable" unless @deployment
          mapping = selected_hint(options[:mapping], "ACE_ASSIGN_LAUNCH_MAPPING")
          @kernel ||= Ace::Runtime::Molecules::ProtectedLinux.new
          Client.new(mapping_id: mapping, deployment: @deployment, kernel: @kernel)
        end

        def mapping_hint?
          !@env["ACE_ASSIGN_LAUNCH_MAPPING"].to_s.empty?
        end

        # Observer/signer commands reuse the installed selection and held
        # descriptor pair. This grants no effect; endpoints authorize the peer.
        def with_inbox_workflow(options:)
          mapping = selected_hint(options[:mapping], "ACE_ASSIGN_LAUNCH_MAPPING")
          project, inbox_context = options.values_at(:project, :inbox_context)
          inbox_context_selection(project: project, mapping: mapping, inbox_context: inbox_context) do |_selection|
            @kernel ||= Ace::Runtime::Molecules::ProtectedLinux.new
            yield @deployment, @kernel, @deployment.mapping(mapping)
          end
        end

        # Consumers call only after original PreparedInput admission. These
        # existing owners select transport; they do not confer a new grant.
        def with_installed_selection(options:, input:)
          raise AttemptErrors::EvidenceUnavailable, "protected installed authority is unavailable" unless @deployment
          mapping = selected_hint(options[:mapping], "ACE_ASSIGN_LAUNCH_MAPPING")
          begin
            map = @deployment.mapping(mapping)
            unless input && input.descriptor.fetch("mapping_id") == mapping &&
                input.descriptor.fetch("project_id") == map.fetch("project_id")
              raise AttemptErrors::EvidenceUnavailable, "original prepared installed selection differs"
            end
          rescue KeyError
            raise AttemptErrors::EvidenceUnavailable, "original installed mapping is unavailable"
          end
          @kernel ||= Ace::Runtime::Molecules::ProtectedLinux.new
          yield @deployment, @kernel, mapping
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
