# frozen_string_literal: true
require "digest"
require "json"
require "securerandom"
require "time"
require "fileutils"
require "open3"
require_relative "deployment"

module Ace
  module Assign
    module Authority
      # Launch facts and release permission live in qjl authority_mutation data.
      # Process handles/streams are observations, never a replacement ledger.
      class LaunchLifecycle
        MUTATIONS = {
          "register_assignment" => %w[mapping_id assignment_id definition_bytes definition_digest expected_generation],
          "reserve_attempt" => %w[mapping_id assignment_id scope worker_uid runtime base_head launcher_process_binding expected_generation],
          "record_launch" => %w[mapping_id assignment_id attempt_id launch_ticket process_binding expected_generation],
          "bind_process" => %w[mapping_id assignment_id attempt_id launch_ticket process_binding expected_generation],
          "release_launch" => %w[mapping_id assignment_id attempt_id launch_ticket process_binding expected_generation],
          "abort_launch" => %w[mapping_id assignment_id attempt_id launch_ticket failure_evidence failure_digest expected_generation]
        }.freeze
        OPERATIONS = (MUTATIONS.keys + %w[launch_preflight registration_status attempt_status inspect_launch]).freeze
        TERMINAL = %w[succeeded failed stopped].freeze

        attr_reader :mutex, :journals, :exclusions
        def initialize(deployment:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new, journals: nil, mutex: Mutex.new, exclusions: {})
          @deployment, @kernel = deployment, kernel
          @journals = journals || {}
          @exclusions = exclusions
          @mutex = mutex
          @observations = {}
          @streams = {}
          @changed = ConditionVariable.new
        end

        def attach_result_owner(owner)
          raise ArgumentError, "result status owner already attached" if @result_owner
          @result_owner = owner
        end

        def dispatch(request:, peer:, role:)
          operation, params = request.values_at("operation", "params")
          if operation == "launch_preflight"
            strict!(params, %w[mapping_id])
            raise AttemptErrors::UnauthorizedIdentity, "preflight requires mapped launcher" unless role == :launcher
            map = @deployment.mapping(params.fetch("mapping_id"))
            return {data: {"project_id" => map.fetch("project_id"), "runtime" => "herdr", "supported" => true}, replayed: false}
          end
          if operation == "registration_status"
            strict!(params, %w[mapping_id assignment_id])
            raise AttemptErrors::UnauthorizedIdentity, "registration status requires mapped launcher" unless role == :launcher
            map = @deployment.mapping(params.fetch("mapping_id"))
            token!(params.fetch("assignment_id"))
            journal = journal_for(map)
            @mutex.synchronize do
              registration = definition(journal, params.fetch("assignment_id"))
              return {data: registration || {"assignment_id" => params.fetch("assignment_id"), "generation" => 0}, replayed: false}
            end
          end
          if operation == "inspect_launch"
            strict!(params, %w[mapping_id assignment_id attempt_id])
            raise AttemptErrors::UnauthorizedIdentity, "inspection requires launcher or supervisor" unless %i[launcher supervisor].include?(role)
            return {data: inspect_launch(params, peer: peer, role: role), replayed: false}
          end
          if operation == "attempt_status"
            keys = %w[mapping_id assignment_id attempt_id]
            keys += ["result_candidate_generation"] if @result_owner
            strict!(params, keys)
            if @result_owner
              raise ArgumentError, "status mutation ID must be null" unless request.fetch("mutation_id").nil?
              selector = params.fetch("result_candidate_generation")
              generation!(selector, allow_nil: true)
            end
            return {data: status(params, peer: peer, role: role), replayed: false}
          end
          unless role == :launcher || (role == :supervisor && operation == "abort_launch")
            raise AttemptErrors::UnauthorizedIdentity, "launch mutation requires mapped launcher or authorized recovery supervisor"
          end
          keys = MUTATIONS.fetch(operation) { raise ArgumentError, "unknown authority operation" }
          strict!(params, keys)
          token!(request.fetch("mutation_id"))
          token!(params.fetch("assignment_id"))
          generation!(params.fetch("expected_generation"), allow_nil: operation == "register_assignment")
          map = @deployment.mapping(params.fetch("mapping_id"))
          bounded_scope!(params.fetch("scope")) if operation == "reserve_attempt"
          @kernel.live!(peer)
          journal = journal_for(map)
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(params)))
          with_exclusion(params, map, journal) do
          @mutex.synchronize do
            replay = journal.mutation_result(request.fetch("mutation_id"))
            attempt_id = replay&.fetch("attempt_id") || mutation_attempt_id(operation, params)
            if operation == "release_launch" && !replay
              deadline = wire.deadline(5)
              until @streams.key?(attempt_id)
                remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                raise AttemptErrors::EvidenceUnavailable, "exact gate readiness is unavailable" if remaining <= 0
                @changed.wait(@mutex, [remaining, 0.1].min)
              end
            end
            reservation_handle = nil
            begin
              fresh = false
              released = false
              result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: attempt_id,
                mutation_id: request.fetch("mutation_id"), operation: operation, parameters_digest: digest,
                expected_generation: operation == "reserve_attempt" ? 0 : (params.fetch("expected_generation") || 0), with_replay: true) do |events, commit, generation|
                fresh = true
                plan = case operation
                when "register_assignment" then register(params, map, journal, commit, generation)
                when "reserve_attempt" then reserve(params, map, journal, commit, generation, peer, attempt_id)
                when "record_launch" then record(params, map, events, peer)
                when "bind_process" then bind(params, map, events, peer)
                when "release_launch"
                  released = true
                  release(params, map, events, peer)
                when "abort_launch" then abort(params, map, events, peer, supervisor: role == :supervisor)
                end
                bounded_reply!(plan.fetch(:data), generation + 1)
                # Validate the complete plan before opening a handle, but acquire
                # it before returning any events for staging/CAS. Reuse across
                # retries; a competing accepted replay never owns this handle.
                reservation_handle ||= @kernel.pin(peer) if operation == "reserve_attempt"
                plan
              end
              fresh = !result.fetch(:replayed)
              result = result.fetch(:data)
              if fresh && operation == "reserve_attempt"
                @observations[result.fetch("attempt_id")] = {launcher: peer, launcher_handle: reservation_handle, deadline: wire.deadline(30), ticket: result.fetch("launch_ticket"), assignment_id: result.fetch("assignment_id")}
                reservation_handle = nil
              end
              # No release in mutation replay. A crash here retains issued uncertainty.
              if fresh && released
                stream = @streams.fetch(result.fetch("attempt_id"))
                permission = {"operation" => "release", "launch_ticket" => result.fetch("launch_ticket"),
                  "attempt_id" => result.fetch("attempt_id"), "assignment_id" => result.fetch("assignment_id"),
                  "generation" => result.fetch("generation"), "journal_commit" => result.fetch("journal_commit")}
                begin
                  wire.write(stream.fetch(:socket), permission, deadline: wire.deadline(1))
                rescue StandardError
                  # Durable permission cannot be undone or retransmitted after write loss.
                  nil
                ensure
                  stream[:issued] = true
                  stream.fetch(:condition).broadcast
                end
              end
              reap_terminal_observations(journal, params.fetch("assignment_id"))
              materialize_definition(result, map, journal) if operation == "register_assignment"
              {data: result, replayed: !fresh}
            ensure
              reservation_handle&.close
            end
          end
          end
        end

        def gate_ready(request:, peer:, socket:, deadline:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id launch_ticket])
          token!(params.fetch("launch_ticket"))
          map = @deployment.mapping(params.fetch("mapping_id"))
          admitted = nil
          until admitted || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            @mutex.synchronize do
              journal = journal_for(map)
              @observations.each do |attempt, observation|
                next unless observation[:ticket] == params["launch_ticket"]
                events = journal.read_events(observation.fetch(:assignment_id))
                state = states(events)[attempt]
                next unless state && state["mapping_id"] == params["mapping_id"] && state["launch_ticket"] == params["launch_ticket"]
                next unless %w[recorded bound].include?(state["phase"])
                identity = state.fetch("process_binding").fetch("process_identity")
                next unless @kernel.same?(peer, identity)
                @kernel.live!(peer)
                next unless observation[:child] && @kernel.same?(observation.fetch(:child), peer) && launcher_live?(observation)
                raise AttemptErrors::Conflict, "gate stream already established" if observation[:gate_established]
                condition = ConditionVariable.new
                admitted = {socket: socket, condition: condition, issued: false, state: state}
                observation[:gate_established] = true
                @streams[attempt] = admitted
                @changed.broadcast
                wire.write(socket, {"status" => "ok", "data" => {"phase" => "ready"}}, deadline: deadline)
                break
              end
            end
            sleep 0.02 unless admitted
          end
          raise AttemptErrors::EvidenceUnavailable, "gate was not positively admitted" unless admitted
          @mutex.synchronize do
            until admitted[:issued]
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              break if remaining <= 0 || !launcher_live?(@observations[admitted.fetch(:state).fetch("attempt_id")])
              admitted.fetch(:condition).wait(@mutex, [remaining, 0.1].min)
            end
          end
        ensure
          if admitted
            @mutex.synchronize { @streams.delete(admitted.fetch(:state).fetch("attempt_id")) }
          end
        end

        # Endcap calls this against its already locked canonical attempt chain.
        # Only launch operations may establish origin; later business mutations
        # cannot replace immutable native identity by echoing launch fields.
        def origin(events, assignment_id:, attempt_id:, mapping_id:)
          state = states(events)[attempt_id]
          unless state && state["assignment_id"] == assignment_id && state["mapping_id"] == mapping_id
            raise AttemptErrors::NotFound, "canonical protected launch origin is missing"
          end
          JSON.parse(JSON.generate(state))
        end

        # Source-owned consumers enter before taking the shared authority mutex.
        # Registration is reread after exclusion; a changed task cannot borrow
        # the lock acquired for a previous registration.
        def with_assignment(params:, map:, exclusive: false)
          id = params.fetch("assignment_id")
          token!(id)
          journal = journal_for(map)
          initial = definition(journal, id)
          raise AttemptErrors::NotFound, "canonical assignment registration is missing" unless initial
          task = initial.fetch("task_id")
          token!(task)
          exclusion = exclusion_for(map, journal)
          enter = proc do
            @mutex.synchronize do
              registration = definition(journal, id)
              unless registration && registration.fetch("task_id") == task
                raise AttemptErrors::Conflict, "assignment registration changed while entering lifecycle exclusion"
              end
              yield journal, JSON.parse(JSON.generate(registration))
            end
          end
          if exclusive
            exclusion.with_exclusive(exclusion.task_key(task)) do
              exclusion.with_exclusive(exclusion.assignment_key(id)) { enter.call }
            end
          else
            exclusion.with_shared_multi([exclusion.task_key(task), exclusion.assignment_key(id)]) { enter.call }
          end
        end

        # Shutdown calls this only after all admitted handlers have ended.
        def close
          @mutex.synchronize do
            @observations.each_value { |observation| close_observation(observation) }
            @observations.clear
          end
        end

        private

        def bounded_scope!(scope)
          unless scope.is_a?(String) && scope.bytesize.between?(1, 128) && scope.split(".", -1).length <= 16
            raise ArgumentError, "assignment scope exceeds protected launch bounds"
          end
          Atoms::AssignmentScope.canonicalize(scope)
        end

        def bounded_reply!(data, generation)
          envelope = {"status" => "ok", "data" => data.merge("generation" => generation, "journal_commit" => "0" * 64),
            "transport" => {"replayed" => false}}
          raise ArgumentError, "accepted launch reply exceeds transport bounds" if JSON.generate(envelope).bytesize + 1 > 16_384
        end

        def close_observation(observation)
          %i[launcher_handle child_handle].each do |key|
            observation[key]&.close
          end
        end

        def reap_terminal_observations(journal, assignment)
          events = journal.read_events(assignment)
          @observations.keys.each do |attempt|
            chain = events.select { |event| event["attempt_id"] == attempt }
            next if chain.empty? || !terminal_events?(chain)
            close_observation(@observations.delete(attempt))
            @streams[attempt]&.fetch(:condition)&.broadcast
          end
        end

        def exclusion_for(map, journal)
          exclusion = @exclusions[map.fetch("project_id")] ||= begin
            common, error, result = Open3.capture3("git", "-C", journal.repo_root,
              "rev-parse", "--path-format=absolute", "--git-common-dir", stdin_data: "")
            raise AttemptErrors::EvidenceUnavailable, "canonical lifecycle root is unavailable" unless result.success? && !common.strip.empty?
            Molecules::LifecycleExclusion.new(root: File.join(common.strip, "ace", "lifecycle-exclusion"))
          end
          exclusion
        end

        def with_exclusion(params, map, journal)
          exclusion = exclusion_for(map, journal)
          registration = definition(journal, params.fetch("assignment_id"))
          task = if params.key?("definition_bytes")
            JSON.parse(params.fetch("definition_bytes")).fetch("task_id")
          else
            registration&.fetch("task_id")
          end
          token!(task)
          keys = [exclusion.task_key(task), exclusion.assignment_key(params.fetch("assignment_id"))]
          exclusion.with_shared_multi(keys) { yield }
        end

        def materialize_definition(result, map, journal)
          project = @deployment.project(map.fetch("project_id"))
          directory = File.join(project.fetch("assignment_root"), result.fetch("assignment_id"))
          raise AttemptErrors::EvidenceUnavailable, "assignment cache is substituted" if File.symlink?(directory)
          FileUtils.mkdir_p(directory, mode: 0o700)
          stat = File.stat(directory)
          unless stat.directory? && stat.uid == Process.uid && (stat.mode & 0o077).zero?
            raise AttemptErrors::EvidenceUnavailable, "assignment cache is not owner-private"
          end
          bytes = journal.blob(result.fetch("definition_ref"), commit: result.fetch("journal_commit"))
          unless Digest::SHA256.hexdigest(bytes) == result.fetch("definition_digest")
            raise AttemptErrors::EvidenceUnavailable, "canonical assignment definition is corrupt"
          end
          temporary = File.join(directory, ".definition-#{SecureRandom.hex(16)}")
          File.open(temporary, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
            file.write(bytes)
            file.flush
            file.fsync
          end
          File.rename(temporary, File.join(directory, "assignment.yaml"))
        ensure
          File.unlink(temporary) if temporary && File.exist?(temporary)
        end

        def journal_for(map)
          @journals[map.fetch("project_id")] ||= begin
            project = @deployment.project(map.fetch("project_id"))
            Molecules::EvidenceJournal.new(repo_root: project.fetch("journal_repository"),
              checkout_root: project.fetch("evidence_checkout_root"), ref: project.fetch("evidence_git_ref"))
          end
        end

        def mutation_attempt_id(operation, params)
          return "definition-#{params.fetch('assignment_id')}" if operation == "register_assignment"
          return "launch-#{SecureRandom.hex(12)}" if operation == "reserve_attempt"
          token!(params.fetch("attempt_id"))
        end

        def register(params, map, journal, commit, generation)
          bytes = params.fetch("definition_bytes")
          unless bytes.is_a?(String) && bytes.bytesize <= 32_768 && params["definition_digest"].is_a?(String) &&
              Digest::SHA256.hexdigest(bytes) == params["definition_digest"]
            raise ArgumentError, "invalid assignment definition digest or size"
          end
          value = JSON.parse(bytes)
          allowed = %w[session_id name description created_at updated_at source_config parent task_id project_id]
          unless value.is_a?(Hash) && (value.keys - allowed).empty? &&
              %w[session_id name created_at source_config task_id project_id].all? { |key| value[key].is_a?(String) && !value[key].empty? } &&
              value["session_id"] == params["assignment_id"] && value["project_id"] == map["project_id"]
            raise ArgumentError, "invalid managed assignment definition"
          end
          assignment = Models::Assignment.from_h(value)
          raise ArgumentError, "definition is not managed" unless assignment.managed?
          previous = definition(journal, params.fetch("assignment_id"), commit: commit)
          if previous && previous["definition_digest"] != params["definition_digest"] && active_events?(journal.read_events(params.fetch("assignment_id")))
            raise AttemptErrors::Conflict, "active assignment definition cannot change"
          end
          path = "execution/definitions/#{params.fetch('assignment_id')}-#{params.fetch('definition_digest')}.json"
          {events: [], blobs: {path => bytes}, data: {"assignment_id" => params.fetch("assignment_id"),
            "project_id" => map.fetch("project_id"), "mapping_id" => params.fetch("mapping_id"),
            "phase" => "registered", "definition_ref" => path, "definition_digest" => params.fetch("definition_digest"),
            "definition_generation" => previous && previous["definition_digest"] == params["definition_digest"] ? previous.fetch("definition_generation") : generation + 1, "task_id" => assignment.task_id}}
        end

        def reserve(params, map, journal, commit, generation, peer, attempt_id)
          registration = definition(journal, params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "assignment is unregistered" unless registration && registration["mapping_id"] == params["mapping_id"]
          unless registration["definition_generation"] == params["expected_generation"] && params["worker_uid"] == map["worker_uid"] &&
              params["runtime"] == "herdr" && @kernel.same?(params["launcher_process_binding"], peer)
            raise AttemptErrors::UnauthorizedIdentity, "reservation identity differs"
          end
          scope = Atoms::AssignmentScope.canonicalize(params.fetch("scope"))
          events = journal.read_events(params.fetch("assignment_id"))
          events.group_by { |event| event["attempt_id"] }.each_value do |chain|
            intent = chain.find { |event| event["type"] == "intent" }
            next unless intent && !terminal_events?(chain)
            old_scope = intent.fetch("payload").fetch("scope")
            if old_scope == scope || old_scope.start_with?("#{scope}.") || scope.start_with?("#{old_scope}.")
              raise AttemptErrors::Conflict, "scope is already owned"
            end
          end
          head = params.fetch("base_head")
          raise ArgumentError, "invalid base revision" unless head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/)
          ticket = SecureRandom.hex(24)
          payload = {"assignment_id" => params.fetch("assignment_id"), "scope" => scope,
            "project_id" => map.fetch("project_id"), "task_id" => registration.fetch("task_id"),
            "base_head" => head, "actor" => map.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr",
            "launcher_identity" => peer, "launch_ticket" => ticket}
          {events: [{type: "intent", payload: payload}], blobs: {}, data: payload.merge(
            "attempt_id" => attempt_id, "phase" => "reserved", "mapping_id" => params.fetch("mapping_id"),
            "reservation_generation" => generation + 1, "handshake_deadline" => (Time.now.utc + 30).iso8601(6))}
        end

        def record(params, map, events, peer)
          state, observation = owned(params, events, peer)
          raise AttemptErrors::Conflict, "launch cannot record another child" unless state["phase"] == "reserved"
          binding = validate_binding!(params.fetch("process_binding"), map, mapping_id: params.fetch("mapping_id"), launch_ticket: params.fetch("launch_ticket"))
          child = binding.fetch("process_identity")
          @kernel.live!(child)
          if observation[:child_handle]
            unless @kernel.same?(observation.fetch(:child), child)
              raise AttemptErrors::Conflict, "record retry differs from observed child"
            end
          else
            observation[:child_handle] = @kernel.pin(child)
            observation[:child] = child
          end
          {events: [], blobs: {}, data: state.merge("phase" => "recorded", "process_binding" => binding)}
        end

        def bind(params, map, events, peer)
          state, = owned(params, events, peer)
          unless state["phase"] == "recorded" && state["process_binding"] == params["process_binding"]
            raise AttemptErrors::Conflict, "binding differs from recorded original child"
          end
          validate_binding!(params.fetch("process_binding"), map, mapping_id: params.fetch("mapping_id"), launch_ticket: params.fetch("launch_ticket"))
          @kernel.live!(params.fetch("process_binding").fetch("process_identity"))
          payload = {"actor" => map.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr",
            "pid" => params.dig("process_binding", "process_identity", "pid"),
            "process_identity" => params.dig("process_binding", "process_identity"), "runtime_binding" => params.fetch("process_binding")}
          {events: [{type: "process_start", payload: payload}], blobs: {}, data: state.merge("phase" => "bound")}
        end

        def release(params, map, events, peer)
          state, observation = owned(params, events, peer)
          unless state["phase"] == "bound" && state["process_binding"] == params["process_binding"] && @streams.key?(state.fetch("attempt_id"))
            raise AttemptErrors::Conflict, "exact live bound gate is unavailable"
          end
          validate_binding!(params.fetch("process_binding"), map, mapping_id: params.fetch("mapping_id"), launch_ticket: params.fetch("launch_ticket"))
          @kernel.live!(observation.fetch(:child))
          raise AttemptErrors::Conflict, "launcher has exited" unless launcher_live?(observation)
          {events: [], blobs: {}, data: state.merge("phase" => "issued", "execution" => "potentially_executed")}
        end

        def abort(params, map, events, peer, supervisor: false)
          state, observation = owned(params, events, peer, require_launcher_live: false, supervisor: supervisor)
          evidence = params.fetch("failure_evidence")
          unless evidence.is_a?(String) && evidence.bytesize <= 16_384 && Digest::SHA256.hexdigest(evidence) == params["failure_digest"]
            raise ArgumentError, "invalid bounded failure evidence"
          end
          issued = events.any? do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "release_launch"
          end
          positive = %w[recorded bound uncertain].include?(state["phase"]) && !issued &&
            state["execution"] != "potentially_executed" && observation[:child_handle] && observation[:child] &&
            state.dig("process_binding", "process_identity") == observation[:child] &&
            @kernel.exited?(observation.fetch(:child_handle))
          target = positive ? "failed" : "uncertain"
          proof = if positive
            {"process_identity" => observation.fetch(:child), "exit_observed_at" => Time.now.utc.iso8601(6),
              "bootstrap_sha256" => map.fetch("bootstrap_sha256"), "server_identity" => map.dig("native", "server_identity"),
              "release" => "not_issued", "yama" => 2, "capability_sets" => "empty", "no_new_privs" => 1}
          end
          evidence_ref = "evidence/imports/launch-failure-#{state.fetch('attempt_id')}-#{params.fetch('failure_digest')}"
          reason = positive ? "protected_gate_exited_before_release" : "protected_launch_requires_positive_termination_proof"
          lifecycle_event = if positive && state["phase"] == "uncertain"
            {type: "reconciliation", payload: {"resolution" => "failed", "reason" => reason,
              "failure_digest" => params.fetch("failure_digest"), "abort_observation" => proof}}
          else
            {type: "transition", payload: {"from" => state["phase"] == "uncertain" ? "uncertain" :
              (%w[bound issued].include?(state["phase"]) ? "running" : "reserved"), "to" => target, "reason" => reason}}
          end
          {events: [lifecycle_event],
            blobs: {evidence_ref => evidence}, data: state.merge("phase" => target, "failure_digest" => params.fetch("failure_digest"),
              "failure_ref" => evidence_ref, "abort_observation" => proof,
              "required_action" => positive ? nil : "supervisor_inspect_exact_child_and_release_uncertainty")}
        end

        def owned(params, events, peer, require_launcher_live: true, supervisor: false)
          state = states(events)[params.fetch("attempt_id")]
          unless state && state["mapping_id"] == params["mapping_id"] && state["launch_ticket"] == params["launch_ticket"] &&
              (supervisor || @kernel.same?(state["launcher_identity"], peer))
            raise AttemptErrors::UnauthorizedIdentity, "launch is not owned by this exact launcher"
          end
          observation = @observations[params.fetch("attempt_id")]
          raise AttemptErrors::EvidenceUnavailable, "exact launch handles require supervisor recovery" unless observation
          if require_launcher_live && observation.fetch(:deadline) <= Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise AttemptErrors::EvidenceUnavailable, "protected launch handshake expired; supervisor inspection required"
          end
          if require_launcher_live && !launcher_live?(observation)
            raise AttemptErrors::Conflict, "launcher has exited"
          end
          [state, observation]
        end

        def validate_binding!(binding, map, mapping_id:, launch_ticket:)
          strict!(binding, %w[runtime session pane terminal_id process_identity shell_identity native_origin])
          raise ArgumentError, "native runtime differs" unless binding["runtime"] == "herdr" && binding["shell_identity"] == binding["process_identity"]
          identity = binding.fetch("process_identity")
          strict!(identity, %w[pid uid gid groups started_at host parent_pid])
          origin = binding.fetch("native_origin")
          strict!(origin, %w[workspace tab pane server_identity socket_identity command cwd])
          unless origin["command"] == [map.fetch("bootstrap"), mapping_id, launch_ticket] && origin["cwd"] == map.fetch("worker_cwd") &&
              binding["terminal_id"].is_a?(String) && !binding["terminal_id"].empty? && binding["session"].is_a?(String) && binding["pane"].is_a?(String)
            raise AttemptErrors::UnauthorizedIdentity, "native origin command or terminal differs"
          end
          server = map.fetch("native").fetch("server_identity")
          unless identity.is_a?(Hash) && identity["uid"] == map["worker_uid"] && identity["gid"] == map["worker_gid"] &&
              identity["groups"] == map["worker_groups"] && identity["parent_pid"] == server["pid"] &&
              binding.dig("native_origin", "server_identity") == server &&
              binding.dig("native_origin", "socket_identity") == map.dig("native", "socket_identity") &&
              binding.dig("native_origin", "workspace") == map.dig("native", "workspace_id") &&
              binding.dig("native_origin", "workspace") == binding["session"] && binding.dig("native_origin", "pane") == binding["pane"]
            raise AttemptErrors::UnauthorizedIdentity, "original native child lineage differs"
          end
          @kernel.live!(server)
          binding
        end

        def launcher_live?(observation)
          return false unless observation && observation[:launcher_handle] && !@kernel.exited?(observation.fetch(:launcher_handle))
          @kernel.live!(observation.fetch(:launcher))
          true
        rescue StandardError
          false
        end

        def definition(journal, id, commit: journal.ref_value)
          journal.read_events(id).reverse.filter_map do |event|
            next unless event["type"] == "authority_mutation" && event.dig("payload", "operation") == "register_assignment"
            event.dig("payload", "data")
          end.first
        end

        def states(events)
          events.each_with_object({}) do |event, result|
            next unless event["type"] == "authority_mutation" && MUTATIONS.key?(event.dig("payload", "operation"))
            data = event.dig("payload", "data")
            next unless data.is_a?(Hash) && data["launch_ticket"]
            result[event.fetch("attempt_id")] = data
          end
        end

        def inspect_launch(params, peer:, role:)
          token!(params.fetch("assignment_id"))
          token!(params.fetch("attempt_id"))
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          @mutex.synchronize do
            state = origin(journal.read_events(params.fetch("assignment_id")), assignment_id: params.fetch("assignment_id"),
              attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
            if role == :launcher && !@kernel.same?(state.fetch("launcher_identity"), peer)
              raise AttemptErrors::UnauthorizedIdentity, "launch belongs to another launcher incarnation"
            end
            identity = state.fetch("process_binding") { raise AttemptErrors::EvidenceUnavailable, "no recorded original child; inspection cannot infer absence" }.fetch("process_identity")
            observation = @observations[params.fetch("attempt_id")]
            if observation && observation[:child_handle] && observation[:child] == identity && @kernel.exited?(observation.fetch(:child_handle))
              return state.merge("journal_commit" => journal.ref_value,
                "termination_observation" => {"status" => "exited", "process_identity" => identity},
                "required_action" => "request_abort_using_retained_exact_exit_proof")
            end
            @kernel.live!(map.dig("native", "server_identity"))
            @kernel.live!(identity)
            unless observation
              child_handle = @kernel.pin(identity)
              @observations[params.fetch("attempt_id")] = {child: identity, child_handle: child_handle,
                launcher: state.fetch("launcher_identity"), launcher_handle: nil, deadline: 0}
            end
            state.merge("journal_commit" => journal.ref_value,
              "termination_observation" => {"status" => "alive", "process_identity" => identity},
              "required_action" => "close_original_native_child_then_request_abort")
          end
        end

        def status(params, peer:, role:)
          map = @deployment.mapping(params.fetch("mapping_id"))
          token!(params.fetch("assignment_id")); token!(params.fetch("attempt_id"))
          journal = journal_for(map)
          @mutex.synchronize do
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit)
            state = states(events)[params.fetch("attempt_id")]
            raise AttemptErrors::NotFound, "launch not found" unless state && state["mapping_id"] == params["mapping_id"]
            if role == :launcher && !@kernel.same?(state.fetch("launcher_identity"), peer)
              raise AttemptErrors::UnauthorizedIdentity, "launch belongs to another launcher incarnation"
            end
            projection = state.slice("assignment_id", "attempt_id", "phase", "scope", "launch_ticket", "reservation_generation", "generation", "execution", "required_action", "handshake_deadline")
            if %i[launcher supervisor].include?(role)
              projection.merge!(state.slice("process_binding", "launcher_identity", "mapping_id"))
            end
            observation = @observations[params.fetch("attempt_id")]
            expired = !%w[issued failed].include?(state["phase"]) && state["handshake_deadline"] && Time.iso8601(state.fetch("handshake_deadline")) <= Time.now.utc
            child_exited = observation && observation[:child_handle] &&
              observation[:child] == state.dig("process_binding", "process_identity") && @kernel.exited?(observation.fetch(:child_handle))
            if !TERMINAL.include?(state["phase"]) && (!observation || !launcher_live?(observation) || expired || child_exited)
              projection.merge!("phase" => "uncertain", "required_action" => "supervisor_inspect_exact_child_and_release_uncertainty")
            end
            if @result_owner
              chain = events.select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              projection.merge!(@result_owner.result_status(journal: journal, events: chain, params: params,
                map: map, peer: peer, role: role, commit: commit))
            end
            projection.merge("journal_commit" => commit)
          end
        end

        def active_events?(events)
          events.group_by { |event| event["attempt_id"] }.values.any? { |chain| chain.any? { |event| event["type"] == "intent" } && !terminal_events?(chain) }
        end
        def terminal_events?(events)
          latest = events.reverse.filter_map do |event|
            case event["type"]
            when "process_start" then "running"
            when "transition" then event.dig("payload", "to")
            when "receipt_accepted" then event.dig("payload", "receipt", "verdict")
            when "reconciliation" then event.dig("payload", "resolution")
            end
          end.first
          TERMINAL.include?(latest)
        end
        def strict!(value, keys)
          raise ArgumentError, "authority fields differ" unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end
        def token!(value)
          raise ArgumentError, "invalid public identifier" unless value.is_a?(String) && Deployment::TOKEN.match?(value)
          value
        end
        def generation!(value, allow_nil: false)
          return if allow_nil && value.nil?
          raise ArgumentError, "invalid journal generation" unless value.is_a?(Integer) && value >= 0
        end
        def canonical(value)
          case value
          when Hash then value.sort.to_h.transform_values { |item| canonical(item) }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end
        def wire
          Ace::Runtime::Molecules::ProtectedSocket
        end
      end
    end
  end
end
