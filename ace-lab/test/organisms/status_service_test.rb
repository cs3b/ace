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

        def test_from_config_resolves_cascade_per_report
          Dir.mktmpdir do |tmp|
            saved = ENV["ACE_RUNTIME"]
            ENV.delete("ACE_RUNTIME")
            begin
              Dir.chdir(tmp) do
                report = StatusService.from_config.report

                assert_equal :defaults_only, report.config[:state]
                assert report.ok?
              end
            ensure
              saved.nil? ? ENV.delete("ACE_RUNTIME") : ENV["ACE_RUNTIME"] = saved
            end
          end
        end

        def test_state_locations_resolve_from_subdirectory_of_the_project
          Dir.mktmpdir("lab-status-root") do |dir|
            system("git", "-C", dir, "init", "--quiet", out: File::NULL, err: File::NULL)
            FileUtils.mkdir_p(File.join(dir, ".ace-tasks"))
            subdir = File.join(dir, "deep", "sub")
            FileUtils.mkdir_p(subdir)

            report = nil
            Dir.chdir(subdir) { report = StatusService.from_config.report }
            entry = report.state.find { |e| e[:key] == "tasks" }

            assert_equal :present, entry[:state],
              "expected .ace-tasks resolved against the project root, got: #{report.state.inspect}"
          end
        end
      end
    end
  end
end
