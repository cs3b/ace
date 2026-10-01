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
          identity_dir: File.join(Dir.pwd, ".ace-local", "herdr", "runtime-tabs"))
          @executor = executor
          @env = env
          @clock = clock
          @sleeper = sleeper
          @surface = surface || ControlSurface.new(executor: executor)
          @prepared = {}
          @identity_dir = identity_dir
        end

        def context
          return {in_runtime: false, session: nil, window: nil, pane: nil} unless inside?

          current = @executor.pane_get(@env["HERDR_PANE"]).parsed_json
          {
            in_runtime: true,
            session: @env["HERDR_WORKSPACE_ID"] || find_value(current, %w[workspace_id workspaceId]),
            window: find_value(current, %w[tab_id tabId]),
            pane: @env["HERDR_PANE"] || find_value(current, %w[pane_id paneId])
          }
        rescue ExecutorUnavailableError => e
          raise Runtime::RuntimeUnavailableError, e.message
        rescue PaneNotFoundError => e
          raise Runtime::TargetNotFoundError, e.message
        end

        def ensure_window(name:, root:, preset: nil)
          with_errors do
            workspace = workspace_id!
            label = Runtime.sanitize_name(name)
            with_identity_lock(workspace, label) do |path|
              existing = tabs(workspace).find { |tab| tab[:name] == label }
              if existing
                verify_identity!(existing, root: root, preset: preset, path: path)
                next existing[:id]
              end

              id = if preset
                created = @surface.create_tab(preset, workspace_id: workspace, cwd: root, label: label)
                created.fetch(:tab)
              else
                parsed = @executor.tab_create(workspace_id: workspace, label: label, cwd: File.expand_path(root)).parsed_json
                find_value(parsed, %w[tab tab_id])
              end
              raise TargetResolutionError, "tab create returned no tab id" if id.nil?

              write_identity(path, id: id, root: canonical_root(root), preset: preset)
              id
            end
          end
        end

        def prepare_pane(window:)
          with_errors do
            tab = resolve_tab!(window)
            cached = @prepared[tab[:id]]
            if cached
              begin
                @executor.pane_get(cached)
                return cached
              rescue PaneNotFoundError
                @prepared.delete(tab[:id])
              end
            end

            root_pane = panes(tab[:workspace]).find { |pane| pane[:tab] == tab[:id] }
            raise Runtime::TargetNotFoundError, "tab '#{window}' has no pane" unless root_pane

            parsed = @executor.pane_split(pane: root_pane[:pane], direction: "right").parsed_json
            id = find_value(parsed, %w[pane pane_id])
            raise TargetResolutionError, "pane split returned no pane id" if id.nil?

            @executor.pane_get(id)
            process_info = @executor.pane_process_info(id).parsed_json
            unless find_value_of_type(process_info, "shell_pid", Integer)
              raise Runtime::RuntimeUnavailableError, "prepared pane '#{id}' has no retained shell"
            end

            @prepared[tab[:id]] = id
          end
        end

        def focus(window:)
          with_errors { @executor.tab_focus(resolve_tab!(window)[:id]); true }
        end

        def send_profile
          :agent_aware
        end

        def send(pane:, command: nil, items: [])
          # Reject malformed shared shapes before probing the target.
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

          deadline = @clock.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
          with_errors(condition: condition, target: target, timeout: timeout) do
            loop do
              return true if lifecycle_met?(condition, target)
              raise Runtime::WaitTimeoutError.new(condition: condition, target: target, timeout: timeout) if
                @clock.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

              @sleeper.sleep(POLL_INTERVAL)
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

        def with_identity_lock(workspace, label)
          FileUtils.mkdir_p(@identity_dir)
          key = Digest::SHA256.hexdigest("#{workspace}\0#{label}")
          path = File.join(@identity_dir, "#{key}.json")
          File.open("#{path}.lock", File::RDWR | File::CREAT, 0o600) do |file|
            file.flock(File::LOCK_EX)
            yield path
          end
        end

        def verify_identity!(tab, root:, preset:, path:)
          native_pane = @surface.list_panes(workspace_id: tab[:workspace]).find { |pane| pane[:tab] == tab[:id] }
          native_root = native_pane && native_pane[:cwd]
          recorded = JSON.parse(File.read(path)) if File.file?(path)
          recorded = nil unless recorded.is_a?(Hash) && recorded["id"] == tab[:id]

          root_matches = if recorded
            recorded["root"] == canonical_root(root)
          else
            native_root && canonical_root(native_root) == canonical_root(root)
          end
          preset_matches = recorded ? recorded["preset"] == preset : preset.nil?
          return if root_matches && preset_matches

          raise Runtime::WindowConflictError, "window '#{tab[:name]}' conflicts with root or preset"
        rescue JSON::ParserError
          raise Runtime::WindowConflictError, "window '#{tab[:name]}' has unreadable root or preset identity"
        end

        def write_identity(path, id:, root:, preset:)
          temp = "#{path}.#{Process.pid}.tmp"
          File.open(temp, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
            file.write(JSON.generate({id: id, root: root, preset: preset}))
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

        def lifecycle_met?(condition, target)
          case condition
          when "window-exists" then tab_exists?(target)
          when "window-active" then tab_active?(target)
          when "pane-exists" then pane_exists?(target)
          when "pane-exited" then pane_exited?(target)
          end
        end

        def tab_exists?(target)
          @executor.tab_get(resolve_tab!(target)[:id])
          true
        rescue Runtime::TargetNotFoundError, TabNotFoundError
          false
        end

        def tab_active?(target)
          tab = resolve_tab!(target)
          @executor.tab_get(tab[:id])
          tab[:active] == true
        rescue Runtime::TargetNotFoundError, TabNotFoundError
          false
        end

        def pane_exists?(target)
          @executor.pane_get(target)
          true
        rescue PaneNotFoundError
          false
        end

        def pane_exited?(target)
          return true unless pane_exists?(target)

          info = @executor.pane_process_info(target).parsed_json
          processes = find_array(info, "foreground_processes")
          return false if processes.nil?

          shell_pid = find_value_of_type(info, "shell_pid", Integer)
          processes.empty? || (shell_pid && processes.all? { |process| process.is_a?(Hash) && process["pid"] == shell_pid })
        rescue PaneNotFoundError
          true
        end

        def find_value(value, keys)
          case value
          when Hash
            keys.each { |key| return value[key] if value[key].is_a?(String) && !value[key].empty? }
            value.each_value { |child| found = find_value(child, keys); return found if found }
          when Array
            value.each { |child| found = find_value(child, keys); return found if found }
          end
          nil
        end

        def find_array(value, key)
          return unless value.is_a?(Hash)
          return value[key] if value[key].is_a?(Array)

          value.each_value { |child| found = find_array(child, key); return found if found }
          nil
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
        rescue WorkspaceNotFoundError => e
          raise Runtime::RuntimeUnavailableError, e.message
        rescue ExecutorUnavailableError => e
          raise Runtime::RuntimeUnavailableError, e.message
        end
      end
    end
  end
end
