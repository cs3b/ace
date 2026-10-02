# frozen_string_literal: true

require "ace/runtime"
require "digest"
require "fileutils"
require "json"

module Ace
  module Herdr
    module Organisms
      # Maps ace-runtime's terminal intents onto herdr's workspace/tab/pane API.
      # Contract session means workspace; contract window means tab.
      class RuntimeAdapter
        POLL_INTERVAL = 0.02

        def initialize(executor: Molecules::HerdrExecutor.new, env: ENV, clock: Process, sleeper: Kernel, surface: nil,
          identity_dir: nil, poll_interval: POLL_INTERVAL)
          @executor = executor
          @env = env
          @clock = clock
          @sleeper = sleeper
          @surface = surface || ControlSurface.new(executor: executor)
          @prepared = {}
          @identity_dir = identity_dir
          @poll_interval = poll_interval
        end

        def context
          return {in_runtime: false, session: nil, window: nil, pane: nil} unless inside?

          with_errors do
            current = @executor.pane_get(@env["HERDR_PANE"]).parsed_json
            native_workspace = find_value(current, %w[workspace_id workspaceId])
            hint = @env["HERDR_WORKSPACE_ID"]
            if hint && native_workspace && hint != native_workspace
              raise Runtime::RuntimeUnavailableError,
                "HERDR_WORKSPACE_ID '#{hint}' does not match the caller pane's workspace " \
                "'#{native_workspace}'; clear the hint or reconnect the pane"
            end

            {
              in_runtime: true,
              session: native_workspace || hint,
              window: find_value(current, %w[tab_id tabId]),
              pane: @env["HERDR_PANE"] || find_value(current, %w[pane_id paneId])
            }
          end
        end

        def ensure_window(name:, root:, preset: nil)
          with_errors do
            workspace = workspace_id!
            label = Runtime.sanitize_name(name)
            with_identity_lock(workspace, label) do
              path = identity_path(workspace, label)
              existing = tabs(workspace).find { |tab| tab[:name] == label }
              if existing
                # Ownership must be proven by the record (or, without one,
                # by the pane's native root for a preset-free request); a
                # tab we cannot verify is never closed or replaced.
                unless verifiable_identity?(existing, root: root, preset: preset, path: path)
                  raise Runtime::WindowConflictError,
                    "window '#{existing[:name]}' conflicts with root or preset"
                end

                # Adopting a record-less tab: persist its provenance (and
                # keep any prepared-pane pointer) so later instances share it.
                if read_identity(path, existing).nil?
                  write_identity(path, id: existing[:id], root: canonical_root(root), preset: preset,
                    prepared_pane: pointer_prepared_pane(path, existing[:id]))
                end
                next existing[:id]
              end

              created_id =
                if preset
                  begin
                    created = @surface.create_tab(preset, workspace_id: workspace, cwd: File.expand_path(root), label: label)
                  rescue TabMaterializationError => e
                    # Roll back the tab this call created — exact id from
                    # the surface, never a listing guess. Best effort: a
                    # rollback failure never replaces the primary error.
                    begin
                      @executor.tab_close(e.tab_id)
                    rescue StandardError => close_error
                      warn "ace-herdr: rollback close failed for tab #{e.tab_id}: #{close_error.class}: #{close_error.message}"
                    end
                    raise
                  end
                  created.fetch(:tab)
                else
                  parsed = @executor.tab_create(workspace_id: workspace, label: label, cwd: File.expand_path(root)).parsed_json
                  find_value(parsed, %w[tab tab_id])
                end
              raise TargetResolutionError, "tab create returned no tab id" if created_id.nil?

              begin
                write_identity(path, id: created_id, root: canonical_root(root), preset: preset)
              rescue StandardError
                begin
                  @executor.tab_close(created_id)
                rescue StandardError => close_error
                  warn "ace-herdr: rollback close failed for tab #{created_id}: #{close_error.class}: #{close_error.message}"
                end
                raise
              end
              created_id
            end
          end
        end

        def prepare_pane(window:)
          with_errors do
            tab = resolve_tab!(window)
            # Hold the identity lock through discovery, split, verification,
            # and recording so concurrent instances cannot split twice.
            with_identity_lock(tab[:workspace], tab[:name]) do
              cached = discover_prepared_pane(tab)
              next cached if cached

              # Split a shell pane: prefer the first pane without a live
              # agent — pane list ordering does not contractually promise
              # a shell root pane in foreign multi-pane tabs. Single-pane
              # tabs skip the probe entirely.
              tab_panes = panes(tab[:workspace]).select { |pane| pane[:tab] == tab[:id] }
              root_pane = tab_panes.first
              if tab_panes.length > 1
                root_pane = tab_panes.find { |pane| !agent_pane?(pane[:pane]) } || tab_panes.first
              end
              raise Runtime::TargetNotFoundError, "tab '#{window}' has no pane" unless root_pane

              parsed = @executor.pane_split(pane: root_pane[:pane], direction: "right").parsed_json
              id = find_value(parsed, %w[pane pane_id])
              raise TargetResolutionError, "pane split returned no pane id" if id.nil?

              verify_retained_shell!(id)
              record_prepared_pane(tab, id)
              id
            end
          end
        end

        def focus(window:)
          with_errors { @executor.tab_focus(resolve_tab!(window)[:id]); true }
        end

        def send_profile
          :agent_aware
        end

        def send(pane:, command: nil, items: [])
          # Reject malformed shared shapes before any delivery or mutation;
          # the agent probe below is a native read, never a write.
          Runtime::Atoms::SendContract.normalize!(command: command, items: items, profile: :plain_pane)
          with_errors do
            agent = agent_pane?(pane)
            request = Runtime::Atoms::SendContract.normalize!(
              command: command, items: items, profile: agent ? :agent_aware : :plain_pane
            )
            if agent
              request.items.each do |item|
                item.key?(:message) ? @executor.agent_prompt(pane: pane, text: item[:message]) :
                  @executor.agent_send_keys(pane, [item[:key]])
              end
            else
              @executor.pane_run(pane, request.command) if request.command
              request.items.each do |item|
                item.key?(:message) ? @executor.pane_send_text(pane, item[:message]) :
                  @executor.pane_send_keys(pane, [item[:key]])
              end
            end
            Runtime::Atoms::SendContract::Result.new(dropped_trailing_enter: request.dropped_trailing_enter)
          end
        end

        def send_command(pane:, command:)
          send(pane: pane, command: command)
        end

        def send_text(pane:, text:)
          send(pane: pane, items: [{message: text}])
        end

        def send_keys(pane:, keys:)
          send(pane: pane, items: Array(keys).map { |key| {key: key} })
        end

        def capture(pane:, lines: 40)
          with_errors { @surface.capture(pane: pane, lines: lines) }
        end

        def wait_output(pane:, pattern:, timeout:)
          with_errors(condition: "output", target: pane, timeout: timeout) do
            @surface.wait_output(pane: pane, pattern: pattern, timeout_ms: milliseconds(timeout))
          end
        end

        def wait_agent(pane:, states:, timeout:)
          with_errors(condition: "agent", target: pane, timeout: timeout) do
            @executor.agent_wait(pane: pane, until_states: states, timeout_ms: milliseconds(timeout))
            true
          end
        end

        def wait_lifecycle(condition:, target:, timeout:)
          unless Runtime::Atoms::SendContract::LIFECYCLE_CONDITIONS.include?(condition)
            raise ArgumentError, "unknown lifecycle condition '#{condition}'"
          end

          # Window conditions resolve the caller workspace once per wait so
          # poll iterations do not re-run context and tab-list subprocesses;
          # pane conditions never need it.
          scope = nil
          deadline = @clock.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
          with_errors(condition: condition, target: target, timeout: timeout) do
            loop do
              if condition.start_with?("window-") && scope.nil?
                scope = workspace_id!
              end
              return true if lifecycle_met?(condition, target, workspace: scope)
              raise Runtime::WaitTimeoutError.new(condition: condition, target: target, timeout: timeout) if
                @clock.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

              @sleeper.sleep(@poll_interval)
            end
          end
        end

        def close_window(window:)
          with_errors { @executor.tab_close(resolve_tab!(window)[:id]); true }
        end

        def list_windows
          with_errors { tabs(workspace_id!).map { |tab| {name: tab[:name], window: tab[:id], active: tab[:active]} } }
        end

        def list_panes(window:)
          with_errors do
            tab = resolve_tab!(window)
            panes(tab[:workspace]).select { |pane| pane[:tab] == tab[:id] }
          end
        end

        private

        def inside?
          !@env["HERDR_SESSION"].to_s.empty? && !@env["HERDR_PANE"].to_s.empty?
        end

        def workspace_id!
          raise Runtime::RuntimeUnavailableError, "not inside a herdr workspace" unless inside?

          context[:session] || raise(Runtime::RuntimeUnavailableError, "herdr workspace is unavailable")
        end

        def tabs(workspace)
          @surface.list_tabs(workspace_id: workspace).map do |row|
            {id: row[:id], name: row[:title], workspace: row[:workspace], active: row[:focused]}
          end
        end

        def panes(workspace)
          @surface.list_panes(workspace_id: workspace).map do |row|
            {pane: row[:id], tab: row[:tab], workspace: row[:workspace]}
          end
        end

        def resolve_tab!(window)
          workspace = workspace_id!
          tab = tabs(workspace).find { |row| row[:id] == window || row[:name] == window }
          tab || raise(Runtime::TargetNotFoundError, "tab '#{window}' not found")
        end

        def canonical_root(root)
          File.realpath(root)
        rescue Errno::ENOENT
          File.expand_path(root)
        end

        # Identity records and locks are keyed on the shared (workspace,
        # label) identity in a stable user-level location — instances from
        # any cwd and any requested root agree on the same record, so
        # concurrent creators of the same label serialize and reuse is
        # verifiable across processes.
        def identity_path(workspace, label)
          base = @identity_dir || File.join(Dir.home, ".ace", "local", "herdr", "runtime-tabs")
          File.join(base, "#{Digest::SHA256.hexdigest("#{workspace}\0#{label}")}.json")
        end

        def with_identity_lock(workspace, label, &_block)
          path = "#{identity_path(workspace, label)}.lock"
          FileUtils.mkdir_p(File.dirname(path))
          File.open(path, File::RDWR | File::CREAT, 0o600) do |file|
            file.flock(File::LOCK_EX)
            yield
          end
        end

        # Reuse needs the recorded identity to match the request; when no
        # readable record exists, native pane cwd is the only remaining
        # root evidence and a preset can never be verified.
        def verifiable_identity?(tab, root:, preset:, path:)
          recorded = read_identity(path, tab)
          if recorded
            return recorded["root"] == canonical_root(root) && recorded["preset"] == preset
          end

          native_root = native_pane_cwd(tab)
          native_root && canonical_root(native_root) == canonical_root(root) && preset.nil?
        end

        # Rollback after a failed create is exact-id only (see ensure_window);
        # listings are never consulted for ownership decisions.

        def read_identity(path, tab)
          recorded = JSON.parse(File.read(path)) if File.file?(path)
          recorded = nil unless recorded.is_a?(Hash) && recorded["id"] == tab[:id]
          # A pointer-only record (no root/preset provenance — written for
          # a foreign tab's prepared pane) proves no ownership.
          recorded = nil if recorded && !recorded.key?("root") && !recorded.key?("preset")
          recorded
        rescue JSON::ParserError
          raise Runtime::WindowConflictError,
            "window '#{tab[:name]}' has unreadable root or preset identity"
        end

        def native_pane_cwd(tab)
          native_pane = @surface.list_panes(workspace_id: tab[:workspace]).find { |pane| pane[:tab] == tab[:id] }
          native_pane && native_pane[:cwd]
        end

        # Cross-instance prepared-pane reuse: the identity record carries
        # the prepared pane id, so another adapter instance (or process)
        # reuses the retained target instead of splitting again. Works for
        # provenance records and pointer-only (foreign tab) records alike.
        def discover_prepared_pane(tab)
          cached = @prepared[tab[:id]]
          return cached if usable_prepared_pane?(cached)

          pane_id = pointer_prepared_pane(identity_path(tab[:workspace], tab[:name]), tab[:id])
          return nil unless pane_id && usable_prepared_pane?(pane_id)

          @prepared[tab[:id]] = pane_id
          pane_id
        end

        def pointer_prepared_pane(path, id)
          raw = JSON.parse(File.read(path))
          raw.is_a?(Hash) && raw["id"] == id ? raw["prepared_pane"] : nil
        rescue JSON::ParserError, Errno::ENOENT
          nil
        end

        def record_prepared_pane(tab, pane_id)
          @prepared[tab[:id]] = pane_id
          path = identity_path(tab[:workspace], tab[:name])
          begin
            recorded = File.file?(path) ? JSON.parse(File.read(path)) : nil
          rescue JSON::ParserError
            # A corrupt record is repaired under the identity lock rather
            # than silently dropped, so the pointer survives.
            recorded = :corrupt
          end
          if recorded.is_a?(Hash) && recorded["id"] == tab[:id]
            write_identity(path, id: recorded["id"], root: recorded["root"], preset: recorded["preset"],
              prepared_pane: pane_id)
          else
            # Foreign tab (not created through ensure_window) or corrupt
            # record: persist a pointer-only record so later instances
            # reuse this pane instead of splitting again.
            write_pointer_only(path, id: tab[:id], prepared_pane: pane_id)
          end
        rescue StandardError => e
          # The pointer is an optimization; losing it only costs a re-split.
          # Warn and continue — provenance writes in ensure_window stay
          # hard-fail, this one does not.
          warn "ace-herdr: could not persist prepared-pane record for '#{tab[:name]}': #{e.class}: #{e.message}"
          nil
        end

        def usable_prepared_pane?(pane_id)
          return false unless pane_id

          @executor.pane_get(pane_id)
          info = find_hash(@executor.pane_process_info(pane_id).parsed_json, %w[result process_info])
          info.is_a?(Hash) && !!find_value_of_type(info, "shell_pid", Integer)
        rescue PaneNotFoundError
          false
        end

        def verify_retained_shell!(pane_id)
          info = find_hash(@executor.pane_process_info(pane_id).parsed_json, %w[result process_info])
          return if info.is_a?(Hash) && find_value_of_type(info, "shell_pid", Integer)

          raise Runtime::Error, "prepared pane '#{pane_id}' has no retained shell"
        end

        def write_identity(path, id:, root:, preset:, prepared_pane: nil)
          payload = {id: id, root: root, preset: preset}
          payload[:prepared_pane] = prepared_pane if prepared_pane
          atomic_write_json(path, payload)
        end

        def write_pointer_only(path, id:, prepared_pane:)
          atomic_write_json(path, {id: id, prepared_pane: prepared_pane})
        end

        def atomic_write_json(path, payload)
          temp = "#{path}.#{Process.pid}.tmp"
          File.open(temp, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
            file.write(JSON.generate(payload))
            file.flush
            file.fsync
          end
          File.rename(temp, path)
        ensure
          File.delete(temp) if temp && File.exist?(temp)
        end

        def agent_pane?(pane)
          @executor.agent_get(pane)
          true
        rescue AgentNotFoundError
          false
        end

        def lifecycle_met?(condition, target, workspace:)
          case condition
          when "window-exists" then tab_exists?(target, workspace: workspace)
          when "window-active" then tab_active?(target, workspace: workspace)
          when "pane-exists" then pane_exists?(target)
          when "pane-exited" then pane_exited?(target)
          end
        end

        def tab_exists?(target, workspace:)
          @executor.tab_get(find_tab(target, workspace)[:id])
          true
        rescue Runtime::TargetNotFoundError, TabNotFoundError
          false
        end

        def tab_active?(target, workspace:)
          tab = find_tab(target, workspace)
          @executor.tab_get(tab[:id])
          tab[:active] == true
        rescue Runtime::TargetNotFoundError, TabNotFoundError
          false
        end

        # Scoped to the workspace resolved once for the enclosing wait.
        def find_tab(target, workspace)
          tabs(workspace).find { |row| row[:id] == target || row[:name] == target } ||
            raise(Runtime::TargetNotFoundError, "tab '#{target}' not found")
        end

        def pane_exists?(target)
          @executor.pane_get(target)
          true
        rescue PaneNotFoundError
          false
        end

        # Mirrors PaneTidyProbe.process_evidence semantics: herdr
        # serializes `foreground_processes` with serde skip_serializing_if,
        # so inside a well-formed result.process_info object an OMITTED key
        # is the process-exit proof; an explicit null or non-array value is
        # malformed evidence and stays inconclusive. Anything alive appears
        # as a non-empty array; a list holding only the retained shell
        # counts as exited (no submitted foreground command remains).
        def pane_exited?(target)
          return true unless pane_exists?(target)

          info = find_hash(@executor.pane_process_info(target).parsed_json, %w[result process_info])
          return false unless info.is_a?(Hash)

          processes = info["foreground_processes"]
          return false if info.key?("foreground_processes") && !processes.is_a?(Array)

          # An omitted list is only trusted exit evidence inside a
          # well-formed object that also carries the pane's shell pid;
          # an empty or shell-only hash alone proves nothing.
          shell_pid = find_value_of_type(info, "shell_pid", Integer)
          return false unless shell_pid

          processes = Array(processes)
          return true if processes.empty?

          processes.all? { |process| process.is_a?(Hash) && process["pid"] == shell_pid }
        rescue PaneNotFoundError
          true
        end

        def find_value(value, keys)
          Atoms::JsonFind.find_value(value, keys)
        end

        # Pinned-path walk that fails closed: nil unless every hop resolves
        def find_hash(value, keys)
          keys.each do |key|
            return nil unless value.is_a?(Hash)

            value = value[key]
          end
          value
        end

        def find_value_of_type(value, key, type)
          return unless value.is_a?(Hash)
          return value[key] if value[key].is_a?(type)

          value.each_value { |child| found = find_value_of_type(child, key, type); return found if found }
          nil
        end

        def milliseconds(seconds)
          (seconds * 1000).ceil
        end

        def with_errors(condition: nil, target: nil, timeout: nil)
          yield
        rescue AgentBlockedError => e
          raise Runtime::SendRejectedError, e.message
        rescue ExecutorTimeoutError, Herdr::WaitTimeoutError => e
          raise Runtime::WaitTimeoutError.new(condition: condition || "send", target: target, timeout: timeout || 0)
        rescue AgentNotReadyError => e
          error = condition ? Runtime::WaitTimeoutError.new(condition: condition, target: target, timeout: timeout) :
            Runtime::SendStalledError.new(e.message)
          raise error
        rescue PaneNotFoundError, TabNotFoundError, AgentNotFoundError => e
          raise Runtime::TargetNotFoundError, e.message
        rescue WorkspaceNotFoundError, TargetResolutionError => e
          # Unresolvable caller context, or the runtime responded but the
          # answer was unusable (missing ids)
          raise Runtime::RuntimeUnavailableError, e.message
        rescue TabMaterializationError, ValidationError, CommandError => e
          # Bad request configuration, a failed materialization, or an
          # unmapped native failure keeps the native cause while surfacing
          # under the contract error type.
          raise Runtime::Error, e.message
        rescue ExecutorUnavailableError => e
          raise Runtime::RuntimeUnavailableError, e.message
        rescue Runtime::Error
          # Already a contract error (raised inside the block): pass through
          # untouched — never re-wrap.
          raise
        rescue StandardError => e
          # Adapter boundary: every runtime failure surfaces under the
          # contract error model, with the native cause preserved.
          raise Runtime::Error, "#{e.class}: #{e.message}"
        end
      end
    end
  end
end
