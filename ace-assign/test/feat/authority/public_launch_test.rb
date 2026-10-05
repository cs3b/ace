# frozen_string_literal: true
require_relative "../../test_helper"

module Ace
  module Assign
    class ProtectedPublicLaunchTest < AceAssignTestCase
      def test_dry_run_only_preflights_without_definition_read_or_mutation
        driver = Object.new
        calls = []
        driver.define_singleton_method(:preflight) { calls << :preflight; {"supported" => true} }
        driver.define_singleton_method(:launch) { |**options| raise "dry-run must not mutate" }
        command = CLI::Commands::Authority::Launch.new
        command.define_singleton_method(:build_driver) { |_mapping| driver }
        output = capture_io { command.call(mapping: "mapping", dry_run: true, definition: "/missing/unreadable.json") }
        assert_equal [:preflight], calls
        assert_equal({"supported" => true}, JSON.parse(output.first))
      end

      def test_public_authority_commands_are_registered
        output = capture_io { assert_equal 0, CLI.start(["help"]) }.first
        %w[serve launch status terminate].each { |name| assert_includes output, "authority #{name}" }
        help = capture_io { assert_equal 0, CLI.start(["authority", "serve", "--help"]) }.first
        refute_includes help, "--config"
      end
    end
  end
end
