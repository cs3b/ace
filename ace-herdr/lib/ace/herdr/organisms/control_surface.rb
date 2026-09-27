# frozen_string_literal: true

module Ace
  module Herdr
    module Organisms
      # Owner of the terminal-control behavior (spec 8wq.t.k84): normalizes
      # herdr's native JSON into the public one-line payloads, routes send
      # input to plain-pane or agent transport, and drives preset
      # instantiation. All native calls go through the executor; command
      # classes render the returned hashes as JSON lines.
      class ControlSurface
        DEFAULT_LINES = 40
        ENTER_KEY = /\Aenter\z/i

        def initialize(executor: Molecules::HerdrExecutor.new)
          @executor = executor
        end

        # --- send -------------------------------------------------------------

        # Ordered send input (tokens: [{type: :cmd|:msg|:key, value: String}]
        # in CLI declaration order). The pane is probed for a live agent:
        # plain panes get raw pane transport in declaration order, agent
        # panes get prompt semantics. Every rejected shape fails before any
        # transport call.
        def send_input(pane:, tokens:)
          validate_send_shapes!(tokens)
          if agent_pane?(pane)
            send_to_agent(pane, tokens)
          else
            send_to_plain(pane, tokens)
          end
        end

        # --- list -------------------------------------------------------------

        # Live panes, optionally scoped to a workspace
        def list_panes(workspace_id: nil)
          result_rows(@executor.pane_list(workspace_id: workspace_id).parsed_json, "panes")
            .map { |row| normalize_pane(row) }
        end

        # Live tabs, optionally scoped to a workspace (tmux windows analogue)
        def list_tabs(workspace_id: nil)
          result_rows(@executor.tab_list(workspace_id: workspace_id).parsed_json, "tabs")
            .map { |row| normalize_tab(row) }
        end

        # Live workspaces (tmux sessions analogue)
        def list_workspaces
          result_rows(@executor.workspace_list.parsed_json, "workspaces")
            .map { |row| normalize_workspace(row) }
        end

        # --- capture ------------------------------------------------------------

        # Raw pane text (visible screen or recent history); no JSON wrapping
        def capture(pane:, source: "recent", lines: DEFAULT_LINES)
          @executor.pane_read(pane, source: source, lines: lines).stdout
        end

        # --- wait: output -------------------------------------------------------

        # Waits for pane output containing a literal pattern. herdr checks
        # existing content immediately, then polls; timeout fails closed.
        def wait_output(pane:, pattern:, timeout_ms:)
          @executor.pane_wait_output(pane, pattern: pattern, timeout_ms: timeout_ms)
          true
        end

        private

        # --- send: validation -------------------------------------------------

        def validate_send_shapes!(tokens)
          raise ValidationError, "Provide at least one of --cmd, --msg, or --key" if tokens.empty?

          tokens.each do |token|
            next unless token[:value].to_s.strip.empty?

            raise ValidationError, "--#{token[:type]} requires a non-blank value"
          end

          cmds = tokens.select { |token| token[:type] == :cmd }
          raise ValidationError, "Use --cmd at most once per send" if cmds.length > 1

          cmd_index = tokens.index { |token| token[:type] == :cmd }
          return unless cmd_index

          raise ValidationError, "Use either --cmd or --msg, not both" if tokens.any? { |token| token[:type] == :msg }

          first_key = tokens.index { |token| token[:type] == :key }
          return unless first_key && first_key < cmd_index

          raise ValidationError,
            "--key must be declared after --cmd; leading or interleaved keys with --cmd are rejected"
        end

        # A live agent switches text input to prompt semantics;
        # agent_not_found proves a plain pane, other failures propagate.
        def agent_pane?(pane)
          @executor.agent_get(pane)
          true
        rescue AgentNotFoundError
          false
        end

        # --- send: plain pane (raw input in declaration order) -----------------

        def send_to_plain(pane, tokens)
          cmd = tokens.find { |token| token[:type] == :cmd }
          if cmd
            @executor.pane_run(pane, cmd[:value])
            keys = tokens.select { |token| token[:type] == :key }
            @executor.pane_send_keys(pane, keys.map { |token| token[:value] }) unless keys.empty?
            return {pane: pane, sent: "cmd"}
          end

          tokens.each do |token|
            case token[:type]
            when :msg then @executor.pane_send_text(pane, token[:value])
            when :key then @executor.pane_send_keys(pane, [token[:value]])
            end
          end
          {pane: pane, sent: tokens.any? { |token| token[:type] == :msg } ? "text" : "keys"}
        end

        # --- send: agent pane (prompt semantics) -------------------------------

        def send_to_agent(pane, tokens)
          cmd = tokens.find { |token| token[:type] == :cmd }
          msgs = tokens.select { |token| token[:type] == :msg }
          keys = tokens.select { |token| token[:type] == :key }
          enter_keys = keys.select { |token| enter_key?(token[:value]) }

          if cmd
            validate_agent_cmd_keys!(keys, enter_keys)
            @executor.agent_prompt(pane: pane, text: cmd[:value])
            return prompt_result(pane, dropped: keys.any?)
          end

          if msgs.any?
            validate_agent_text_keys!(tokens, keys, enter_keys)
            @executor.agent_prompt(pane: pane, text: msgs.map { |token| token[:value] }.join("\n"))
            return prompt_result(pane, dropped: enter_keys.any?)
          end

          raise ValidationError, "On agent panes at most one --key Enter is allowed" if enter_keys.length > 1

          @executor.agent_send_keys(pane, keys.map { |token| token[:value] })
          {pane: pane, sent: "keys"}
        end

        # With --cmd, agent panes accept at most one trailing Enter (dropped)
        def validate_agent_cmd_keys!(keys, enter_keys)
          return if keys.length == enter_keys.length && enter_keys.length <= 1

          raise ValidationError,
            "--cmd with keys on an agent pane allows at most one trailing --key Enter"
        end

        # With text, agent panes accept at most one Enter and only as the
        # final token; any other key combination is rejected
        def validate_agent_text_keys!(tokens, keys, enter_keys)
          unless keys.length == enter_keys.length && enter_keys.length <= 1
            raise ValidationError,
              "On agent panes text may only be followed by a single --key Enter"
          end
          return unless enter_keys.length == 1 && !enter_keys.first.equal?(tokens.last)

          raise ValidationError,
            "On agent panes the single --key Enter must trail the text"
        end

        def prompt_result(pane, dropped:)
          result = {pane: pane, sent: "prompt"}
          result[:dropped_keys] = ["Enter"] if dropped
          result
        end

        def enter_key?(key)
          key.to_s.match?(ENTER_KEY)
        end

        # --- list: normalization ----------------------------------------------

        def normalize_pane(row)
          {
            id: row["pane_id"],
            tab: row["tab_id"],
            workspace: row["workspace_id"],
            title: row["terminal_title_stripped"] || row["terminal_title"],
            cwd: row["cwd"],
            focused: row["focused"],
            agent_status: row["agent_status"]
          }
        end

        def normalize_tab(row)
          {
            id: row["tab_id"],
            workspace: row["workspace_id"],
            title: row["label"],
            number: row["number"],
            pane_count: row["pane_count"],
            focused: row["focused"]
          }
        end

        def normalize_workspace(row)
          {
            id: row["workspace_id"],
            title: row["label"],
            number: row["number"],
            tab_count: row["tab_count"],
            pane_count: row["pane_count"],
            focused: row["focused"]
          }
        end

        # herdr list responses nest rows under result.<key>; anything else is
        # an explicit empty state, never an error
        def result_rows(parsed, key)
          rows = parsed.is_a?(Hash) && parsed["result"].is_a?(Hash) ? parsed["result"][key] : nil
          rows.is_a?(Array) ? rows : []
        end
      end
    end
  end
end
