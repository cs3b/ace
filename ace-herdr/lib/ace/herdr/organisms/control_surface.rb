# frozen_string_literal: true

require "shellwords"

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
        # Preset split directions: herdr-native right/down plus the tmux-ish
        # horizontal/vertical aliases
        DIRECTIONS = {
          "right" => "right", "down" => "down",
          "horizontal" => "right", "vertical" => "down"
        }.freeze
        WORKSPACE_KEYS = %w[workspace_id workspaceId].freeze

        def initialize(
          executor: Molecules::HerdrExecutor.new,
          preset_loader: Molecules::PresetLoader.new,
          default_agent_kind: "pi",
          agent_start_timeout_ms: 60_000
        )
          @executor = executor
          @preset_loader = preset_loader
          @default_agent_kind = default_agent_kind
          @agent_start_timeout_ms = agent_start_timeout_ms
        end

        # Config-driven construction (mirrors Dispatcher.from_config)
        def self.from_config(executor:, config: {})
          timeouts = config["timeouts"] || {}
          new(
            executor: executor,
            default_agent_kind: config["default_agent_kind"] || "pi",
            agent_start_timeout_ms: (timeouts["agent_start"] || 60) * 1000
          )
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

        # --- presets ------------------------------------------------------------

        # Merged preset inventory across the cascade, optionally scoped
        def list_presets(type: nil)
          return @preset_loader.list_all unless type

          unless Molecules::PresetLoader::PRESET_TYPES.include?(type)
            raise ValidationError,
              "Unknown preset type '#{type}' (available: #{Molecules::PresetLoader::PRESET_TYPES.join(', ')})"
          end

          {type => @preset_loader.list(type)}
        end

        # Create a workspace from a preset (tmux `start` analogue); --cwd
        # overrides the resolved root/tab cwd. All tab layouts are validated
        # before any herdr call so a broken preset creates nothing.
        def create_workspace(preset_name, cwd: nil)
          resolved = resolve_workspace_preset(preset_name)
          tabs = Array(resolved["tabs"])
          tabs.each { |tab| preflight_tab!(tab) }

          result = @executor.workspace_create(
            label: resolved["label"] || preset_name,
            cwd: expand_cwd(cwd || resolved["cwd"]),
            focus: resolved["focus"]
          )
          parsed = result.parsed_json
          workspace_id = dig_value(parsed, %w[result workspace workspace_id]) ||
            raise(TargetResolutionError,
              "could not read the new workspace id from herdr workspace create output")
          inherited_cwd = expand_cwd(cwd || resolved["cwd"])

          created_tabs = tabs.map do |tab|
            instantiate_tab(
              tab, workspace_id: workspace_id,
              inherited_cwd: inherited_cwd, cli_cwd: expand_cwd(cwd)
            )
          end

          # herdr seeds every new workspace with an initial tab; the preset's
          # declared tabs replace it
          native_tab_id = dig_value(parsed, %w[result tab tab_id])
          @executor.tab_close(native_tab_id) if native_tab_id && tabs.any?

          {workspace: workspace_id, tabs: created_tabs}
        end

        # Create a tab from a preset (tmux `window` analogue) in the given
        # or resolved workspace; --cwd overrides the resolved tab cwd. The
        # layout is validated before the tab is created.
        def create_tab(preset_name, workspace_id: nil, cwd: nil, label: nil)
          workspace_id = resolve_workspace_id(workspace_id)
          resolved = resolve_tab_preset(preset_name)
          resolved = resolved.merge("label" => label) if label
          preflight_tab!(resolved)
          instantiate_tab(
            resolved, workspace_id: workspace_id,
            inherited_cwd: nil, cli_cwd: expand_cwd(cwd)
          )
        end

        # Unknown-preset CLI error listing the available names
        def unknown_preset!(type, name)
          available = @preset_loader.list(type)
          listing = available.empty? ? "none available" : "available: #{available.join(', ')}"
          noun = type == "tabs" ? "tab" : "workspace"
          raise ValidationError, "Unknown #{noun} preset '#{name}' (#{listing})"
        end

        private

        # --- presets: resolution -------------------------------------------------

        def resolve_workspace_preset(name)
          raw = @preset_loader.load("workspaces", name)
          unknown_preset!("workspaces", name) if raw.nil?
          Molecules::PresetResolver.resolve_workspace(
            raw,
            workspace_lookup: @preset_loader.to_lookup("workspaces"),
            tab_lookup: @preset_loader.to_lookup("tabs")
          )
        end

        def resolve_tab_preset(name)
          raw = @preset_loader.load("tabs", name)
          unknown_preset!("tabs", name) if raw.nil?
          Molecules::PresetResolver.resolve_tab(raw, tab_lookup: @preset_loader.to_lookup("tabs"))
        end

        # --- presets: workspace/tab instantiation ---------------------------------

        # Static layout validation before any herdr call: panes declared,
        # every split well-formed with a target that is already placed at
        # its position, and every non-root pane placed by exactly one split
        def preflight_tab!(tab_spec)
          label = tab_spec["label"]
          pane_specs = Array(tab_spec["panes"])
          raise ValidationError, "Preset tab '#{label}' declares no panes" if pane_specs.empty?
          return if pane_specs.length == 1 && Array(tab_spec["splits"]).empty?

          splits = Array(tab_spec["splits"])
          root_label = pane_specs.first["label"]
          placed_labels = [root_label].compact

          splits.each do |split|
            unless split["pane"] && pane_specs.drop(1).any? { |spec| spec["label"] == split["pane"] }
              raise ValidationError,
                "Preset tab '#{label}': splits entry must name a declared non-root pane " \
                "(pane: <label>), got '#{split['pane']}'"
            end

            target = split["target"] || root_label
            unless target.nil? || placed_labels.include?(target)
              raise ValidationError,
                "Preset tab '#{label}': splits entry targets pane '#{target}' before it is placed " \
                "(order splits so each target is created by an earlier split or is the root pane)"
            end
            normalize_direction(split["direction"])
            placed_labels << split["pane"]
          end

          pane_specs.drop(1).each_with_index do |spec, index|
            key = spec["label"] || "panes[#{index + 1}]"
            unless splits.any? { |split| split["pane"] == spec["label"] }
              raise ValidationError,
                "Preset tab '#{label}': pane '#{key}' is not placed " \
                "(add a splits entry with pane: '#{key}')"
            end
          end

          duplicates = splits.map { |split| split["pane"] }
            .tally.select { |_label, count| count > 1 }.keys
          return unless duplicates.any?

          raise ValidationError,
            "Preset tab '#{label}': panes placed by multiple splits: #{duplicates.join(', ')}"
        end

        # Layout first (tab + splits in declared order), then pane commands,
        # then agents (readiness-gated by agent start; vs0 bootstrap order)
        def instantiate_tab(tab_spec, workspace_id:, inherited_cwd:, cli_cwd: nil)
          # cwd precedence: CLI --cwd beats the preset tab cwd, which beats
          # the inherited workspace root cwd
          tab_cwd = cli_cwd || expand_cwd(tab_spec["cwd"]) || inherited_cwd
          tab_json = @executor.tab_create(
            workspace_id: workspace_id,
            label: tab_spec["label"],
            cwd: tab_cwd,
            focus: tab_spec["focus"]
          ).parsed_json
          tab_id = dig_value(tab_json, %w[result tab tab_id]) ||
            raise(TargetResolutionError, "could not read the new tab id from herdr tab create output")

          pane_specs = Array(tab_spec["panes"])
          root_pane_id = dig_value(tab_json, %w[result root_pane pane_id]) ||
            raise(TargetResolutionError, "could not read the root pane id from herdr tab create output")
          placed = place_panes(tab_spec, pane_specs, tab_cwd, root_pane_id)

          commands = run_pane_commands(placed)
          agents = start_pane_agents(placed, workspace_id: workspace_id)

          {
            tab: tab_id,
            panes: placed.map { |pane| pane[:id] },
            commands: commands,
            agents: agents
          }
        end

        # A pane spec: {"label" =>, "cwd" =>, "command" =>, "agent" =>};
        # the first declared pane is the tab's root pane, every further pane
        # must be placed by a splits entry
        def place_panes(tab_spec, pane_specs, inherited_cwd, root_pane_id)
          root_spec = pane_specs.first
          placed = [{spec: root_spec, id: root_pane_id, cwd: pane_cwd(root_spec, inherited_cwd)}]
          rename_pane(root_pane_id, root_spec["label"]) if root_spec["label"]
          by_label = {}
          by_label[root_spec["label"]] = placed[0] if root_spec["label"]

          splits = Array(tab_spec["splits"])

          splits.each do |split|
            spec = pane_spec_for(pane_specs, split["pane"])
            target_label = split["target"] || pane_specs.first["label"]
            target =
              if target_label
                by_label.fetch(target_label) do
                  raise ValidationError,
                    "Preset splits entry targets unknown pane '#{target_label}'"
                end
              else
                placed[0]
              end
            direction = normalize_direction(split["direction"])
            new_id = dig_value(
              @executor.pane_split(
                pane: target[:id], direction: direction,
                cwd: pane_cwd(spec, inherited_cwd),
                ratio: split["ratio"], focus: split["focus"]
              ).parsed_json,
              %w[result pane pane_id]
            ) || raise(TargetResolutionError, "could not read the new pane id from herdr pane split output")
            rename_pane(new_id, spec["label"]) if spec["label"]
            entry = {spec: spec, id: new_id, cwd: pane_cwd(spec, inherited_cwd)}
            placed << entry
            by_label[spec["label"]] = entry if spec["label"]
          end

          placed
        end

        def pane_spec_for(pane_specs, label)
          return pane_specs.first if label.nil?

          pane_specs.find { |spec| spec["label"] == label } ||
            raise(ValidationError, "Preset splits entry references unknown pane '#{label}'")
        end

        def normalize_direction(direction)
          mapped = DIRECTIONS[direction.to_s]
          return mapped if mapped

          raise ValidationError,
            "Unknown split direction '#{direction}' (available: #{DIRECTIONS.keys.join(', ')})"
        end

        def pane_cwd(spec, inherited_cwd)
          expand_cwd(spec["cwd"] || inherited_cwd)
        end

        def expand_cwd(path)
          return nil if path.nil? || path.to_s.empty?

          File.expand_path(path)
        end

        def rename_pane(pane_id, label)
          @executor.pane_rename(pane_id, label)
        end

        def run_pane_commands(placed)
          placed.count do |pane|
            command = pane[:spec]["command"]
            next false if command.nil? || command.to_s.empty?

            @executor.pane_run(pane[:id], command)
            true
          end
        end

        # vs0 bootstrap order: export the reverse address, start the agent
        # (native readiness gate), then submit the declared prompt
        def start_pane_agents(placed, workspace_id:)
          placed.filter_map do |pane|
            agent = pane[:spec]["agent"]
            next nil unless agent.is_a?(Hash)

            pane_id = pane[:id]
            name = agent["name"] || pane[:spec]["label"] || "agent"
            @executor.pane_run(
              pane_id,
              "export HERDR_SESSION=#{Shellwords.escape(workspace_id.to_s)} " \
              "HERDR_PANE=#{Shellwords.escape(pane_id)}"
            )
            @executor.agent_start(
              name: name, kind: agent["kind"] || @default_agent_kind,
              pane: pane_id, timeout_ms: @agent_start_timeout_ms
            )
            prompt = agent["prompt"].to_s
            @executor.agent_prompt(pane: pane_id, text: prompt) unless prompt.empty?
            name
          end
        end

        # Caller's workspace wins by default: explicit flag, then the herdr
        # environment of the calling pane, then the pane current projection
        # (same policy as Dispatcher)
        def resolve_workspace_id(workspace_id)
          return workspace_id if workspace_id

          env = ENV["HERDR_WORKSPACE_ID"].to_s
          return env unless env.empty?

          json = @executor.pane_current.parsed_json
          find_value(json, WORKSPACE_KEYS) ||
            raise(TargetResolutionError,
              "cannot resolve the caller's herdr workspace " \
              "(pass --workspace, run inside a herdr pane, or start herdr)")
        end

        def dig_value(json, path)
          current = json
          path.each do |key|
            return nil unless current.is_a?(Hash)

            current = current[key]
          end
          current.is_a?(String) && !current.empty? ? current : nil
        end

        # Recursive search mirroring the Dispatcher's tolerant extraction of
        # ids from native responses (native shapes nest under result.*)
        def find_value(json, keys)
          case json
          when Hash
            keys.each { |key| return json[key] if json[key].is_a?(String) && !json[key].empty? }
            json.each_value do |value|
              found = find_value(value, keys)
              return found if found
            end
            nil
          when Array
            json.each do |value|
              found = find_value(value, keys)
              return found if found
            end
            nil
          end
        end

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
