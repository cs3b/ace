# frozen_string_literal: true

require "test_helper"


module Ace
  module Lab
    module Organisms
      class StatusServiceTest < Minitest::Test
        DEFAULTS = {
          path: "/gem/.ace-defaults/lab/config.yml",
          document: {"schema_version" => 1, "topology": {"projects" => [], "agents" => [], "services" => []}},
          defaults: true
        }.freeze

        def test_assembles_classifier_and_scanner_outputs
          Dir.mktmpdir do |tmp|
            Dir.mkdir(File.join(tmp, ".ace-tasks"))
            service = StatusService.new(root: tmp)
            report = service.build(documents: [DEFAULTS])

            assert_equal :defaults_only, report.config[:state]
            assert_equal :present, report.state.find { |entry| entry[:key] == "tasks" }[:state]
            assert report.ok?
          end
        end

        def test_cascade_error_flows_into_invalid_section
          Dir.mktmpdir do |tmp|
            service = StatusService.new(root: tmp)
            report = service.build(documents: nil, cascade_error: "invalid lab configuration: /p could not be parsed as YAML")

            assert_equal :invalid, report.config[:state]
            refute report.ok?
            assert_equal :absent, report.state.first[:state]
          end
        end

        def test_injected_root_honored_for_runtime_echo
          Dir.mktmpdir do |tmp|
            FileUtils.mkdir_p(File.join(tmp, ".ace/runtime"))
            File.write(File.join(tmp, ".ace/runtime/config.yml"), "runtime: herdr\n")
            service = StatusService.new(root: tmp)
            report = service.build(documents: [DEFAULTS])

            assert_equal "herdr", report.runtime_config[:runtime]
          end
        end

        def test_from_config_constructs_on_defaults_only
          Dir.mktmpdir do |tmp|
            ENV.delete("ACE_RUNTIME")
            Dir.chdir(tmp) do
              report = StatusService.from_config

              assert_equal :defaults_only, report.config[:state]
              assert report.ok?
            end
          end
        end
      end
    end
  end
end
