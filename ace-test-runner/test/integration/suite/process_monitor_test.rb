# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"
require "tmpdir"

module Ace
  module TestRunner
    module Suite
      class ProcessMonitorTest < Minitest::Test
        class FakeProcessMonitor < ProcessMonitor
          def initialize(command_map:, **kwargs)
            max_parallel = kwargs.delete(:max_parallel) || 10
            super(max_parallel, **kwargs)
            @command_map = command_map
          end

          private

          def build_command(package, _options)
            @command_map.fetch(package["name"])
          end
        end

        def test_timeout_kills_slow_package_and_starts_queued_package
          Dir.mktmpdir do |tmpdir|
            slow_pkg = package_config(tmpdir, "ace-slow")
            fast_pkg = package_config(tmpdir, "ace-fast")
            statuses = Hash.new { |hash, key| hash[key] = [] }

            monitor = FakeProcessMonitor.new(
              command_map: {
                "ace-slow" => ["ruby", "-e", "sleep 5"],
                "ace-fast" => ["ruby", "-e", "puts '1 tests, 1 assertions, 0 failures, 0 errors (0.01s)'"]
              },
              max_parallel: 1,
              # Keep the slow package well above the timeout threshold while giving the
              # queued fast package enough headroom to start under suite-wide load.
              package_timeout: 1.0,
              termination_grace_period: 0.05
            )

            [slow_pkg, fast_pkg].each do |pkg|
              monitor.start_package(pkg, {}) do |package, status, _output|
                statuses[package["name"]] << status.dup
              end
            end

            wait_until(timeout: 5) do
              monitor.check_processes
              !monitor.running?
            end

            slow_status = statuses["ace-slow"].find { |status| status[:completed] }
            fast_status = statuses["ace-fast"].find { |status| status[:completed] }

            refute_nil slow_status
            refute_nil fast_status
            assert slow_status[:timed_out]
            refute slow_status[:success]
            assert_equal "Timed out after 1.0 seconds", slow_status.dig(:results, :error)
            assert fast_status[:success]
          end
        end

        def test_stop_all_terminates_active_package_processes
          Dir.mktmpdir do |tmpdir|
            pkg = package_config(tmpdir, "ace-slow")

            monitor = FakeProcessMonitor.new(
              command_map: {
                "ace-slow" => ["ruby", "-e", "sleep 5"]
              },
              max_parallel: 1,
              package_timeout: 10,
              termination_grace_period: 0.05
            )

            monitor.start_package(pkg, {}) { |_package, _status, _output| }
            pid = monitor.processes.fetch("ace-slow")[:pid]

            monitor.stop_all(reason: :interrupt)

            assert_empty monitor.processes
            assert process_dead?(pid), "expected package subprocess #{pid} to be terminated"
          end
        end

        private

        def package_config(root, name)
          path = File.join(root, name)
          FileUtils.mkdir_p(path)
          {"name" => name, "path" => path}
        end

        def wait_until(timeout:, interval: 0.02)
          deadline = Time.now + timeout
          until yield
            raise "condition not met within #{timeout}s" if Time.now > deadline

            sleep interval
          end
        end

        def process_dead?(pid)
          Process.kill(0, pid)
          false
        rescue Errno::ESRCH
          true
        end
      end
    end
  end
end
