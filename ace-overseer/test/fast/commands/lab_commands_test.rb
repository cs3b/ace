# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative "../../test_helper"

class LabCommandsTest < AceOverseerTestCase
  class FakeLabClient
    attr_reader :calls

    def initialize(result: "ok", error: nil)
      @result = result
      @error = error
      @calls = []
    end

    def call(*arguments, **options)
      @calls << {arguments: arguments, options: options}
      raise @error if @error

      @result
    end
  end

  def test_projects_and_agents_forward_json_commands
    projects = FakeLabClient.new(result: [{"name" => "ace"}])
    agents = FakeLabClient.new(result: [{"name" => "builder-codex"}])

    capture_io { Ace::Overseer::CLI::Commands::Projects.new(client: projects).call }
    capture_io { Ace::Overseer::CLI::Commands::Agents.new(client: agents).call }

    assert_equal %w[project list --json], projects.calls.first[:arguments]
    assert_equal %w[agents --json], agents.calls.first[:arguments]
  end

end
