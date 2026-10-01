# frozen_string_literal: true

require "ace/runtime/testing"

module HerdrContractSupport
  class FixtureEnv
    def initialize(fixture)
      @fixture = fixture
    end

    def [](key)
      context = @fixture.context
      return nil unless context[:in_runtime]

      case key
      when "HERDR_SESSION" then "default"
      when "HERDR_PANE" then context[:pane] || "context-pane"
      when "HERDR_WORKSPACE_ID" then context[:session]
      end
    end
  end

  # Native-shaped bridge to the packaged ScriptedRuntime contract fixture.
  # The production adapter is the system under test; this bridge only
  # replaces the external herdr executable.
  class ScriptedExecutor
    def initialize(fixture)
      @fixture = fixture
    end

    def pane_get(pane)
      guard!
      if pane == "context-pane" || pane == @fixture.context[:pane]
        return result(pane: {pane_id: @fixture.context[:pane], tab_id: @fixture.context[:window],
          workspace_id: @fixture.context[:session]})
      end
      pane!(pane)
      result(pane: {pane_id: pane, tab_id: window_id(@fixture.panes[pane][:window]),
        workspace_id: "main"})
    end

    def tab_list(workspace_id: nil)
      guard!
      rows = @fixture.windows.map do |name, info|
        {tab_id: info[:id], label: name, workspace_id: "main", focused: info[:focused]}
      end
      result(tabs: workspace_id == "main" ? rows : [])
    end

    def pane_list(workspace_id: nil)
      guard!
      rows = @fixture.panes.map do |id, pane|
        next unless @fixture.windows.key?(pane[:window])
        {pane_id: id, tab_id: window_id(pane[:window]), workspace_id: "main",
          cwd: @fixture.windows[pane[:window]][:root]}
      end.compact
      result(panes: workspace_id == "main" ? rows : [])
    end

    def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
      guard!
      id = create_window(label, cwd, nil)
      result(tab_id: id)
    end

    def create_with_preset(label:, cwd:, preset:)
      guard!
      create_window(label, cwd, preset)
    end

    def tab_get(tab)
      guard!
      window!(tab)
      result(tab: {tab_id: tab})
    end

    def tab_focus(tab)
      guard!
      @fixture.focus_window(window!(tab))
      result(tab_id: tab)
    end

    def tab_close(tab)
      guard!
      @fixture.kill_window(window!(tab))
      result(tab_id: tab)
    end

    def pane_split(pane:, direction:, cwd: nil, ratio: nil, focus: nil)
      guard!
      pane!(pane)
      id = @fixture.split_window(@fixture.panes[pane][:window])
      @fixture.set_keep_alive(id, true)
      result(pane_id: id)
    end

    def pane_process_info(pane)
      guard!
      pane!(pane)
      alive = @fixture.alive?(pane)
      result(process_info: {shell_pid: 42,
        foreground_processes: alive ? [{pid: 99}] : []})
    end

    def agent_get(pane)
      guard!
      pane!(pane)
      result(agent: {state: @fixture.agent_state(pane)})
    end

    def agent_prompt(pane:, text:)
      guard!
      pane!(pane)
      @fixture.write_text(pane, text)
      result(state: "working")
    rescue Ace::Runtime::Testing::FixtureStall => e
      raise Ace::Herdr::AgentNotReadyError, e.message
    end

    def agent_send_keys(pane, keys)
      guard!
      pane!(pane)
      keys.each { |key| @fixture.press_key(pane, key) }
      result(sent: "keys")
    end

    def pane_read(pane, source: "recent", lines: nil)
      guard!
      pane!(pane)
      raw_result(@fixture.capture_output(pane, lines: lines || 40))
    end

    def pane_wait_output(pane, pattern:, source: "recent", lines: nil, timeout_ms: nil)
      guard!
      pane!(pane)
      output = @fixture.capture_output(pane, lines: lines || 40)
      raise Ace::Herdr::WaitTimeoutError, "timeout" unless output.include?(pattern)

      result(matched: true)
    end

    def agent_wait(pane:, until_states:, timeout_ms:)
      guard!
      pane!(pane)
      state = @fixture.agent_state(pane)
      raise Ace::Herdr::AgentNotReadyError, "timeout" unless until_states.include?(state)

      result(state: state)
    end

    private

    def create_window(label, cwd, preset)
      id = @fixture.create_window(name: label, root: cwd, preset: preset)
      @fixture.seed_pane(label)
      id
    end

    def window_id(name)
      @fixture.windows[name][:id]
    end

    def window!(id)
      name = @fixture.windows.find { |_name, info| info[:id] == id }&.first
      raise Ace::Herdr::TabNotFoundError, "tab_not_found" unless name

      name
    end

    def pane!(id)
      raise Ace::Herdr::PaneNotFoundError, "pane_not_found" unless @fixture.pane_exists?(id)
    end

    def guard!
      raise Ace::Herdr::ExecutorUnavailableError, "unavailable" if @fixture.unavailable?
    end

    def result(**payload)
      raw_result(JSON.generate(result: payload))
    end

    def raw_result(stdout)
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: stdout, stderr: "", success: true, exit_code: 0)
    end
  end

  class ScriptedSurface < Ace::Herdr::Organisms::ControlSurface
    def create_tab(preset_name, workspace_id: nil, cwd: nil, label: nil)
      {tab: @executor.create_with_preset(label: label, cwd: cwd, preset: preset_name)}
    end
  end
end
