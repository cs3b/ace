# frozen_string_literal: true

# Resolve monorepo dependencies from workspace sources, not installed gems
# (the installed ace-hitl may lag the in-repo version).
%w[ace-hitl ace-support-config ace-support-core].each do |pkg|
  lib = File.expand_path("../../#{pkg}/lib", __dir__)
  $LOAD_PATH.unshift(lib) if Dir.exist?(lib)
end

require "ace/herdr"
require "ace/hitl"

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"

module HerdrTestHelper
  # FakeExecutor records herdr commands without executing them. Outcomes are
  # keyed by executor operation (e.g. :agent_get, :agent_prompt) and may be:
  # an ExecutionResult (success), an Exception (raised), or a Proc receiving
  # the keyword args. Default outcome is success.
  class FakeExecutor
    attr_reader :calls

    def initialize(outcomes: {})
      @calls = []
      @outcomes = outcomes
    end

    def agent_get(pane)
      call(:agent_get, pane: pane)
    end

    def agent_start(name:, kind:, pane:, timeout_ms:)
      call(:agent_start, name: name, kind: kind, pane: pane, timeout_ms: timeout_ms)
    end

    def agent_prompt(pane:, text:)
      call(:agent_prompt, pane: pane, text: text)
    end

    def agent_wait(pane:, until_states:, timeout_ms:)
      call(:agent_wait, pane: pane, until_states: until_states, timeout_ms: timeout_ms)
    end

    def pane_run(pane, command)
      call(:pane_run, pane: pane, command: command)
    end

    def pane_rename(pane, label)
      call(:pane_rename, pane: pane, label: label)
    end

    def pane_close(pane)
      call(:pane_close, pane: pane)
    end

    def pane_current
      call(:pane_current)
    end

    def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
      call(:tab_create, workspace_id: workspace_id, label: label, cwd: cwd, focus: focus)
    end

    def workspace_list
      call(:workspace_list)
    end

    def tab_list(workspace_id: nil)
      call(:tab_list, workspace_id: workspace_id)
    end

    def pane_list(workspace_id: nil)
      call(:pane_list, workspace_id: workspace_id)
    end

    def pane_send_text(pane, text)
      call(:pane_send_text, pane: pane, text: text)
    end

    def pane_send_keys(pane, keys)
      call(:pane_send_keys, pane: pane, keys: keys)
    end

    def agent_send_keys(pane, keys)
      call(:agent_send_keys, pane: pane, keys: keys)
    end

    def pane_read(pane, source: "recent", lines: nil)
      call(:pane_read, pane: pane, source: source, lines: lines)
    end

    def pane_wait_output(pane, pattern:, source: "recent", lines: nil, timeout_ms: nil)
      call(:pane_wait_output, pane: pane, pattern: pattern, source: source, lines: lines, timeout_ms: timeout_ms)
    end

    def workspace_create(label:, cwd: nil, focus: nil)
      call(:workspace_create, label: label, cwd: cwd, focus: focus)
    end

    def pane_split(pane:, direction:, cwd: nil, ratio: nil, focus: nil)
      call(:pane_split, pane: pane, direction: direction, cwd: cwd, ratio: ratio, focus: focus)
    end

    # All invocations of one operation, in order
    def calls_of(operation)
      @calls.select { |c| c[:operation] == operation }
    end

    private

    def call(operation, args = {})
      @calls << {operation: operation, args: args}
      outcome = @outcomes[operation]
      outcome = outcome.call(args) if outcome.respond_to?(:call)
      raise outcome if outcome.is_a?(Exception)

      outcome || success
    end

    def success
      Ace::Herdr::Molecules::ExecutionResult.new(
        stdout: "{}", stderr: "", success: true, exit_code: 0
      )
    end
  end

  # Run block with ENV entries set, restoring afterwards
  def with_env(overrides)
    saved = overrides.transform_keys(&:to_s).keys.to_h { |k| [k, ENV[k]] }
    overrides.each { |k, v| ENV[k.to_s] = v }
    yield
  ensure
    saved.each { |k, v| ENV[k] = v }
  end

  # Build an ace-hitl Ref from session/pane (values must satisfy Ref::TOKEN_PATTERN)
  def make_ref(session = "ws-1", pane = "p5")
    Ace::Hitl::Providers::Ref.new(session: session, pane: pane)
  end
end

class Minitest::Test
  include HerdrTestHelper
end
