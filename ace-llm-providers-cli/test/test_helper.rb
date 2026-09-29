# frozen_string_literal: true

require "minitest/autorun"
require "minitest/spec"

# Require the gem
require_relative "../lib/ace/llm/providers/cli"

# Builds typed CaptureResult objects for stubbing SafeCapture/execute_* methods
# in client tests. Mirrors what SafeCapture returns for each outcome kind.
module CaptureStubHelpers
  def build_capture(stdout: "", stderr: "", success: true, outcome: nil, signal: nil,
    exit_status: nil, provider_name: "Test")
    killed = !signal.nil?
    code = killed ? nil : (exit_status || (success ? 0 : 1))
    status = Object.new
    status.define_singleton_method(:success?) { success && !killed }
    status.define_singleton_method(:exitstatus) { code }
    status.define_singleton_method(:termsig) { killed ? Signal.list.fetch(signal, 0) : nil }
    status.define_singleton_method(:exited?) { !killed }

    outcome ||= killed ? :transport_failure : :completed
    Ace::LLM::Providers::CLI::Models::CaptureResult.new(
      outcome: outcome,
      stdout: stdout,
      stderr: stderr,
      status: outcome == :spawn_failure ? nil : status,
      signal: signal,
      provider_name: provider_name
    )
  end
end

Minitest::Test.include CaptureStubHelpers
Minitest::Spec.include CaptureStubHelpers
