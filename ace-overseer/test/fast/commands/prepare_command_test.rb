# frozen_string_literal: true

require_relative "../../test_helper"

class PrepareCommandTest < AceOverseerTestCase
  class FakeLabClient
    attr_reader :calls

    def initialize
      @calls = []
    end

    def call(*arguments, **options)
      @calls << {arguments: arguments, options: options}
      "prepared"
    end
  end

  def test_forwards_reviewed_title_and_source_to_lab
    client = FakeLabClient.new
    command = Ace::Overseer::CLI::Commands::Prepare.new(client: client)

    capture_io do
      command.call(
        runtime: "lab",
        project: "nervus",
        source: "lab-plan:oauth-callback",
        work: "W142",
        planner: "admin-agy",
        title: "OAuth callback validation"
      )
    end

    assert_equal [
      "work", "prepare", "nervus",
      "--source", "lab-plan:oauth-callback",
      "--work", "W142",
      "--planner", "admin-agy",
      "--title", "OAuth callback validation"
    ], client.calls.first[:arguments]
    assert_equal false, client.calls.first[:options][:json]
  end
end
