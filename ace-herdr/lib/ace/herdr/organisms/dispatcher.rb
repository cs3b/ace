# frozen_string_literal: true

module Ace
  module Herdr
    module Organisms
      # One-command subagent dispatch (spec 8wm.t.vs0 scope extension):
      # tab + herdr agent start + prompt with deterministic defaults —
      # same workspace as the caller, label = agent name, prompt from
      # file or stdin. Zero-token: no LLM decisions here.
      class Dispatcher
        PANE_KEYS = %w[pane_id paneId].freeze
        WORKSPACE_KEYS = %w[workspace_id workspaceId].freeze

        def initialize(executor:, default_agent_kind:, agent_start_timeout_ms:)
          @executor = executor
          @default_agent_kind = default_agent_kind
          @agent_start_timeout_ms = agent_start_timeout_ms
        end

        def self.from_config(executor:, config: {})
          timeouts = config["timeouts"] || {}
          new(
            executor: executor,
            default_agent_kind: config["default_agent_kind"] || "pi",
            agent_start_timeout_ms: (timeouts["agent_start"] || 60) * 1000
          )
        end

        # @param label [String] agent name and pane label (typically the task id)
        # @param prompt [String] initial prompt submitted after readiness
        # @param kind [String, nil] agent kind (default: config default_agent_kind)
        # @param workspace_id [String, nil] target herdr workspace
        #   (default: caller's workspace via env or pane current)
        # @param pane [String, nil] existing pane to start the agent in;
        #   when omitted a new tab is created in the workspace
        # @param cwd [String, nil] working directory for a created tab
        # @return [Models::DispatchOutcome]
        # @raise [TargetResolutionError] workspace/pane cannot be resolved
        # @raise [ExecutorError] herdr command failures
        def dispatch(label:, prompt:, kind: nil, workspace_id: nil, pane: nil, cwd: nil)
          kind ||= @default_agent_kind
          tab_created = false

          workspace_id = resolve_workspace(workspace_id)
          unless pane
            pane = create_tab(workspace_id, label, cwd)
            tab_created = true
          end

          @executor.pane_run(pane, "export HERDR_SESSION=#{workspace_id} HERDR_PANE=#{pane}")
          @executor.agent_start(
            name: label, kind: kind, pane: pane, timeout_ms: @agent_start_timeout_ms
          )

          prompted = false
          unless prompt.empty?
            @executor.agent_prompt(pane: pane, text: prompt)
            prompted = true
          end

          Models::DispatchOutcome.new(
            workspace_id: workspace_id, pane: pane, agent_name: label,
            kind: kind, tab_created: tab_created, prompted: prompted
          )
        end

        private

        # Caller's workspace wins by default: explicit flag, then the herdr
        # environment of the calling pane, then the pane current projection
        def resolve_workspace(workspace_id)
          return workspace_id if workspace_id

          env = ENV["HERDR_WORKSPACE_ID"].to_s
          return env unless env.empty?

          json = @executor.pane_current.parsed_json
          from_json(json, WORKSPACE_KEYS) ||
            raise(TargetResolutionError,
              "cannot resolve the caller's herdr workspace " \
              "(pass --workspace, run inside a herdr pane, or start herdr)")
        end

        def create_tab(workspace_id, label, cwd)
          result = @executor.tab_create(workspace_id: workspace_id, label: label, cwd: cwd)
          from_json(result.parsed_json, PANE_KEYS) ||
            raise(TargetResolutionError,
              "could not read the new pane id from herdr tab create output " \
              "(pass --pane with an existing pane instead)")
        end

        def from_json(json, keys)
          case json
          when Hash
            keys.each { |k| return json[k] if json[k].is_a?(String) && !json[k].empty? }
            json.values.each do |value|
              found = from_json(value, keys)
              return found if found
            end
            nil
          when Array
            json.each do |value|
              found = from_json(value, keys)
              return found if found
            end
            nil
          end
        end
      end
    end
  end
end
