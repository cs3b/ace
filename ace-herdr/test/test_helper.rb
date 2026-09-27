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

    def tab_create(workspace_id:, label:, cwd: nil)
      call(:tab_create, workspace_id: workspace_id, label: label, cwd: cwd)
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
