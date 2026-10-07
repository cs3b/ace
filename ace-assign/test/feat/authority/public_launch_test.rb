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

      class FlushOutput < StringIO
        attr_reader :flushes
        def initialize
          super
          @flushes = 0
        end
        def flush
          @flushes += 1
          super
        end
      end

      def with_launch_command(result: {"phase" => "issued", "attempt_id" => "attempt"}, ready: nil)
        ready ||= {"version" => 1, "type" => "launch_ready", "mapping_id" => "mapping",
          "assignment_id" => "assignment", "attempt_id" => "attempt", "generation" => 3,
          "journal_commit" => "a" * 40, "original_binding_digest" => "b" * 64}
        driver = Object.new
        events = []
        driver.define_singleton_method(:launch) { |**| events << :launch; result }
        driver.define_singleton_method(:serve_control!) do |state:, &emit|
          raise "wrong original state" unless state.equal?(result)
          events << :control
          emit.call(ready)
          events << :returned
        end
        driver.define_singleton_method(:request_control_cancel) { events << :cancel }
        command = CLI::Commands::Authority::Launch.new
        command.define_singleton_method(:build_driver) { |_| driver }
        Dir.mktmpdir("public-launch-") do |root|
          definition = File.join(root, "definition.json")
          File.write(definition, '{}')
          bundle = File.join(root, "prepared.bundle")
          File.binwrite(bundle, "retained bundle")
          options = {mapping: "mapping", assignment: "assignment", definition: definition,
            prepared_bundle: bundle,
            step: "010", base_head: "a" * 40, mutation: "invocation"}
          yield command, driver, events, options, ready, result
        end
      end

      def test_retained_inputs_refuse_symlinks_special_files_and_oversize_before_launch
        with_launch_command do |command, _driver, events, options|
          root = File.dirname(options.fetch(:definition))
          link = File.join(root, "link")
          File.symlink(options.fetch(:definition), link)
          fifo = File.join(root, "fifo")
          File.mkfifo(fifo, 0600)
          oversized = File.join(root, "oversized")
          File.binwrite(oversized, "x" * 32_769)
          [link, fifo, root, oversized].each do |path|
            assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(definition: path)) }
            assert_empty events
          end
          File.binwrite(options.fetch(:definition), "\xff".b)
          assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
          assert_empty events
        end
      end

      def test_ready_is_flushed_before_original_foreground_control_returns
        with_launch_command do |command, driver, events, options, ready, result|
          output = FlushOutput.new
          original_stdout = $stdout
          driver.define_singleton_method(:serve_control!) do |state:, &emit|
            raise "wrong original state" unless state.equal?(result)
            events << :control
            emit.call(ready)
            raise "readiness was not flushed" unless output.flushes == 1 && JSON.parse(output.string) == ready
            events << :retained_after_readiness
          end
          $stdout = output
          command.call(**options)
          assert_equal [:launch, :control, :retained_after_readiness, :cancel], events
          assert_equal [JSON.generate(ready) + "\n"], output.string.lines
        ensure
          $stdout = original_stdout if original_stdout
        end
      end

      def test_nonissued_and_replayed_reservation_return_without_control_or_readiness
        %w[reserved uncertain failed].each do |phase|
          result = {"phase" => phase, "required_action" => "inspect_retained_reservation_no_creation_permission"}
          with_launch_command(result: result) do |command, _driver, events, options|
            output = capture_io { command.call(**options) }.first
            assert_equal result, JSON.parse(output)
            assert_equal [:launch], events
            refute_includes output, "launch_ready"
          end
        end
      end

      def test_malformed_or_mismatched_ready_emits_nothing_and_cancels_local_loop
        with_launch_command do |command, driver, events, options, ready|
          [ready.merge("version" => 1.0), ready.merge("mapping_id" => "other"),
            ready.merge("assignment_id" => "other"), ready.merge("attempt_id" => "other"),
            ready.merge("generation" => 0), ready.merge("journal_commit" => "a" * 41),
            ready.merge("extra" => true)].each do |invalid|
            driver.define_singleton_method(:serve_control!) { |state:, &emit| emit.call(invalid) }
            output = capture_io do
              assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
            end.first
            assert_empty output
            assert_equal :cancel, events.last
          end
          huge = "x" * 16_384
          driver.define_singleton_method(:serve_control!) { |state:, &emit| emit.call(ready.merge("mapping_id" => huge)) }
          output = capture_io do
            assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(mapping: huge)) }
          end.first
          assert_empty output
        end
      end

      def test_duplicate_readiness_or_lost_control_never_prints_a_second_success
        with_launch_command do |command, driver, events, options, ready|
          [:duplicate, :lost].each do |failure|
            driver.define_singleton_method(:serve_control!) do |state:, &emit|
              emit.call(ready)
              raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "control uncertain" if failure == :lost
              emit.call(ready)
            end
            output = capture_io do
              assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
            end.first
            assert_equal [JSON.generate(ready) + "\n"], output.lines
            assert_equal :cancel, events.last
          end
        end
      end

      def test_control_return_without_readiness_is_not_a_successful_launch
        with_launch_command do |command, driver, events, options|
          driver.define_singleton_method(:serve_control!) { |**| nil }
          output = capture_io do
            assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
          end.first
          assert_empty output
          assert_equal [:launch, :cancel], events
        end
      end

      def test_interrupt_preserves_uncertainty_and_only_cancels_local_control_loop
        with_launch_command do |command, driver, events, options|
          driver.define_singleton_method(:serve_control!) { |**| raise Interrupt }
          output = capture_io { assert_raises(Interrupt) { command.call(**options) } }.first
          assert_empty output
          assert_equal [:launch, :cancel], events
        end
      end

      def test_public_authority_commands_are_registered
        output = capture_io { assert_equal 0, CLI.start(["help"]) }.first
        %w[serve launch status terminate].each { |name| assert_includes output, "authority #{name}" }
        help = capture_io { assert_equal 0, CLI.start(["authority", "serve", "--help"]) }.first
        refute_includes help, "--config"
        launch_help = capture_io { assert_equal 0, CLI.start(["authority", "launch", "--help"]) }.first
        assert_includes launch_help, "--prepared-bundle"
        with_launch_command do |command, _driver, events, options|
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.reject { |key, _| key == :prepared_bundle }) }
          assert_empty events
        end
      end
    end
  end
end
