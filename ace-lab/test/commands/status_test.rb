# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class StatusTest < Minitest::Test
          DEFAULTS_DOCUMENT = {
            path: "/gem/.ace-defaults/lab/config.yml",
            document: {"schema_version" => 1, "topology": {"projects" => [], "agents" => [], "services" => []}},
            defaults: true
          }.freeze

          FakeService = Struct.new(:report_value) do
            def report
              report_value
            end
          end

          def build_report(config: {state: :defaults_only, error: nil, topology: {projects: 0, agents: 0, services: 0}},
                           runtime: {state: :absent, source: nil, path: nil, runtime: nil},
                           state: [])
            Models::StatusReport.new(config: config, runtime_config: runtime, state: state, root: "/tmp/project")
          end

          def call_cmd(report, options = {})
            cmd = Status.new(status_service: FakeService.new(report))
            capture_io { cmd.call(**{format: "table", quiet: nil}.merge(options)) }
          end

          def default_locations
            Molecules::LabStateScanner::LOCATIONS.map do |location|
              {key: location[:key], path: location[:path], state: :absent, entries: nil, note: location[:note]}
            end
          end

          def test_defaults_only_renders_missing_not_ready_empty_lab
            out, = call_cmd(build_report(state: default_locations))

            assert_includes out, "Lab configuration: missing (defaults only"
            assert_includes out, "Local state (root: /tmp/project)"
          end

          def test_configured_renders_source_and_counts
            out, = call_cmd(build_report(
              config: {state: :configured, source_path: "/tmp/project/.ace/lab/config.yml", error: nil,
                       topology: {projects: 2, agents: 3, services: 1}},
              state: default_locations
            ))

            assert_includes out, "Lab configuration: configured — /tmp/project/.ace/lab/config.yml"
            assert_includes out, "2 project(s), 3 agent(s), 1 service(s)"
          end

          def test_worktree_line_points_to_k9y_view
            out, = call_cmd(build_report(state: default_locations))

            assert_includes out, "enriched view: ace-git-worktree list"
          end

          def test_private_and_reserved_locations_are_informational
            locations = default_locations.map do |location|
              case location[:key]
              when "overseer", "coworker" then location.merge(state: :prepared)
              else location
              end
            end
            out, = call_cmd(build_report(state: locations))

            assert_includes out, "prepared"
            assert_includes out, "private; not listed"
            assert_includes out, "reserved L3; informational"
          end

          def test_json_format_emits_full_schema
            out, = call_cmd(build_report(state: default_locations), format: "json")

            parsed = JSON.parse(out)
            assert parsed.key?("config")
            assert parsed.key?("runtime_config")
            assert_equal 6, parsed["state"].length
            assert_equal true, parsed["ok"]
          end

          def test_invalid_config_prints_full_report_then_raises
            report = build_report(
              config: {state: :invalid, error: "invalid lab configuration: /p could not be parsed as YAML",
                       topology: {projects: 0, agents: 0, services: 0}},
              state: default_locations
            )

            out, error = nil
            capture_io do
              out = begin
                call_cmd(report)
                nil
              rescue Ace::Support::Cli::Error => e
                error = e
              end
              out = $stdout.string if out.nil? && error
            end

            assert error, "expected Ace::Support::Cli::Error"
            assert_includes error.message, "could not be parsed"
          end

          def test_invalid_config_output_precedes_raise
            report = build_report(
              config: {state: :invalid, error: "boom", topology: {projects: 0, agents: 0, services: 0}},
              state: default_locations
            )
            cmd = Status.new(status_service: FakeService.new(report))

            out, = capture_io do
              begin
                cmd.call(format: "table", quiet: nil)
                flunk "expected Ace::Support::Cli::Error"
              rescue Ace::Support::Cli::Error => e
                assert_includes e.message, "boom"
              end
            end

            assert_includes out, "Lab configuration: invalid — boom"
            assert_includes out, "Local state"
          end

          def test_location_error_raises_alongside_results
            locations = default_locations.map do |location|
              location[:key] == "hitl" ? location.merge(state: :error, note: "Permission denied") : location
            end
            report = build_report(state: locations)

            error = assert_raises(Ace::Support::Cli::Error) { call_cmd(report) }

            assert_includes error.message, "Permission denied"
          end

          def test_quiet_suppresses_output
            out, = call_cmd(build_report(state: default_locations), quiet: true)

            assert_equal "", out
          end

          def test_invalid_format_is_a_usage_error
            assert_raises(Ace::Support::Cli::Error) { call_cmd(build_report, format: "xml") }
          end
        end
      end
    end
  end
end
