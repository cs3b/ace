# frozen_string_literal: true

require "test_helper"
require "stringio"
require "ace/support/config/cli"

module Ace
  module Support
    module Config
      class CLITest < TestCase
        def test_help_uses_ace_config_command_name
          output = capture_io { CLI.start(["help"]) }.first

          assert_includes output, "ace-config - Configuration management"
          assert_includes output, "ace-config COMMAND [OPTIONS]"
          assert_includes output, "doctor"
        end

        def test_version_prints_ace_support_config_version
          output = capture_io { CLI.start(["version"]) }.first

          assert_equal "ace-config #{Ace::Support::Config::VERSION}\n", output
        end

        def test_unknown_command_exits_with_help
          output, = capture_io do
            error = assert_raises(SystemExit) { CLI.start(["bogus"]) }
            assert_equal 1, error.status
          end

          assert_includes output, "Unknown command: bogus"
          assert_includes output, "ace-config COMMAND [OPTIONS]"
        end

        def test_list_includes_usage_footer
          Models::ConfigTemplates.reset!
          output = nil

          Models::ConfigTemplates.stub(:all_gems, ["ace-demo"]) do
            Models::ConfigTemplates.stub(:gem_info, {"ace-demo" => {source: :local, path: "/tmp/demo"}}) do
              Models::ConfigTemplates.stub(:example_dir_for, nil) do
                output = capture_io { CLI.start(["list"]) }.first
              end
            end
          end

          assert_includes output, "ace-demo [local]"
          assert_includes output, "Use 'ace-config sync [GEM]'"
        ensure
          Models::ConfigTemplates.reset!
        end

        def test_sync_help_documents_config_sync_command
          output = capture_io do
            error = assert_raises(SystemExit) { CLI.start(["sync", "--help"]) }
            assert_equal 0, error.status
          end.first

          assert_includes output, "ace-config sync - Sync configuration for ace-* gems"
          assert_includes output, "ace-config sync [GEM] [OPTIONS]"
          assert_includes output, "--force"
          assert_includes output, "--dry-run"
          assert_includes output, "--global"
          assert_includes output, "--verbose"
        end

        def test_init_is_not_supported
          output, = capture_io do
            error = assert_raises(SystemExit) { CLI.start(["init"]) }
            assert_equal 1, error.status
          end

          assert_includes output, "Unknown command: init"
          assert_includes output, "sync [GEM]"
        end

        def test_doctor_invokes_setup_doctor_with_default_options
          received = nil
          doctor = Object.new
          doctor.define_singleton_method(:run) do |**kwargs|
            received = kwargs
            0
          end

          Organisms::SetupDoctor.stub(:new, doctor) do
            capture_io { CLI.start(["doctor"]) }
          end

          assert_equal({json: false, no_probe: false, probe: false, hygiene: false, verbose: false, colors: true, quiet: false}, received)
        end

        def test_doctor_supports_json_no_probe_probe_and_hygiene
          received = nil
          doctor = Object.new
          doctor.define_singleton_method(:run) do |**kwargs|
            received = kwargs
            0
          end

          Organisms::SetupDoctor.stub(:new, doctor) do
            capture_io { CLI.start(["doctor", "--json", "--no-probe", "--probe", "--hygiene"]) }
          end

          assert_equal({json: true, no_probe: true, probe: true, hygiene: true, verbose: false, colors: true, quiet: false}, received)
        end

        def test_doctor_supports_reporter_parity_flags
          received = nil
          doctor = Object.new
          doctor.define_singleton_method(:run) do |**kwargs|
            received = kwargs
            0
          end

          Organisms::SetupDoctor.stub(:new, doctor) do
            capture_io { CLI.start(["doctor", "--verbose", "--quiet", "--no-color"]) }
          end

          assert_equal({json: false, no_probe: false, probe: false, hygiene: false, verbose: true, colors: false, quiet: true}, received)
        end

        def test_doctor_help_documents_probe_controls_and_hygiene_details
          output = capture_io do
            error = assert_raises(SystemExit) { CLI.start(["doctor", "--help"]) }
            assert_equal 0, error.status
          end.first

          assert_includes output, "--probe"
          assert_includes output, "live provider probes"
          assert_includes output, "--no-probe"
          assert_includes output, "Disable live provider probes"
          assert_includes output, "--hygiene"
          assert_includes output, "Show full hygiene findings"
          assert_includes output, "--verbose"
          assert_includes output, "Show full diagnostic detail"
          assert_includes output, "--quiet"
          assert_includes output, "Suppress output"
          assert_includes output, "--no-color"
          assert_includes output, "Disable colored output"
        end

        def test_doctor_exits_non_zero_when_blockers_exist
          doctor = Object.new
          doctor.define_singleton_method(:run) do |**_kwargs|
            1
          end

          Organisms::SetupDoctor.stub(:new, doctor) do
            error = assert_raises(SystemExit) { capture_io { CLI.start(["doctor"]) } }
            assert_equal 1, error.status
          end
        end
      end
    end
  end
end
