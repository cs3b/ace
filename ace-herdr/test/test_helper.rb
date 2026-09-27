# frozen_string_literal: true

require "ace/herdr"
require "ace/hitl"

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"

module HerdrTestHelper
  # FakeExecutor records herdr commands without executing them.
  # Responses are keyed by the subcommand head (e.g. "agent prompt")
  # and may be fixed values or callables receiving the argv array.
  class FakeExecutor
    attr_reader :commands

    def initialize(responses: {})
      @commands = []
      @responses = responses
    end

    def run(cmd)
      @commands << cmd
      response = @responses[response_key(cmd)]
      response = response.call(cmd) if response.respond_to?(:call)
      response || default_result
    end

    # Commands with a given subcommand head, in order
    def commands_for(head)
      @commands.select { |cmd| cmd[0, head.split(" ").length] == head.split(" ") }
    end

    private

    def response_key(cmd)
      case cmd.first
      when "agent" then cmd.take(2).join(" ")
      else cmd.first
      end
    end

    def default_result
      Ace::Herdr::Molecules::ExecutionResult.new(
        stdout: "", stderr: "", success: true, exit_code: 0
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
end

class Minitest::Test
  include HerdrTestHelper
end
