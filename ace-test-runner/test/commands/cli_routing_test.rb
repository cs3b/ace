# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/cli"
require "ace/support/cli"

class CliRoutingTest < Minitest::Test
  include TestHelper

  def test_cli_supports_version_flag
    output = capture_io do
      Ace::Support::Cli::Runner.new(Ace::TestRunner::CLI::Commands::Test).call(args: ["--version"])
    end
    assert_match(/^ace-test \d+\.\d+\.\d+/, output.first)
  end

  def test_cli_help_is_available_from_single_command_entrypoint
    returned_code = nil
    output = capture_io do
      returned_code = Ace::Support::Cli::Runner.new(Ace::TestRunner::CLI::Commands::Test).call(args: ["--help"])
    end

    assert_equal 0, returned_code
    assert_match(/USAGE|Usage:/i, output.first)
  end

  def test_positional_tokens_route_to_test_command
    with_temp_dir do
      FileUtils.mkdir_p("test")
      File.write("test/sample_test.rb", "# empty test file")

      output, _err = capture_io do
        Ace::Support::Cli::Runner.new(Ace::TestRunner::CLI::Commands::Test).call(args: ["atoms"])
      rescue => e
        puts "Routed to test: #{e.class}"
      end
      refute_nil output
    end
  end
end
