# frozen_string_literal: true

require "fileutils"
require "json"
require "yaml"
require "time"

module Ace
  module Scheduler
    module Molecules
      class StateManager
        LOCK_TIMEOUT = 30

        def initialize(state_dir: ".ace/scheduler/state")
          @state_dir = state_dir
        end

        def record_run(task, result)
          with_lock do
            state = load_state
            state[task.to_s] = {
              "last_run" => Time.now.utc.iso8601,
              "status" => result.status,
              "duration" => result.duration,
              "exit_code" => result.exit_code
            }

            save_state(state)
            append_history(task, result)
          end
        end

        def load_state
          path = state_file
          return {} unless File.exist?(path)

          YAML.safe_load_file(path, permitted_classes: [], aliases: true) || {}
        end

        def recent_history(limit: 10)
          history_dir = File.join(@state_dir, "history")
          return [] unless Dir.exist?(history_dir)

          files = Dir.glob(File.join(history_dir, "*.jsonl")).sort.reverse
          entries = []

          files.each do |file|
            File.readlines(file).reverse_each do |line|
              entries << JSON.parse(line)
              return entries.take(limit) if entries.length >= limit
            end
          end

          entries
        rescue Errno::ENOENT
          # No history file exists yet - expected scenario
          []
        rescue JSON::ParserError => e
          warn "[StateManager] Corrupt history entry: #{e.message}"
          []
        rescue StandardError => e
          warn "[StateManager] Error reading history: #{e.class} - #{e.message}"
          []
        end

        private

        def with_lock
          FileUtils.mkdir_p(@state_dir)
          File.open(lock_file, File::RDWR | File::CREAT) do |file|
            deadline = Time.now + LOCK_TIMEOUT
            until file.flock(File::LOCK_EX | File::LOCK_NB)
              if Time.now >= deadline
                raise Ace::Scheduler::Error, "Failed to acquire state lock within #{LOCK_TIMEOUT}s"
              end
              sleep 0.1
            end
            yield
          ensure
            file.flock(File::LOCK_UN)
          end
        end

        def save_state(state)
          FileUtils.mkdir_p(@state_dir)
          File.write(state_file, state.to_yaml)
        end

        def append_history(task, result)
          history_dir = File.join(@state_dir, "history")
          FileUtils.mkdir_p(history_dir)

          date = Time.now.utc.strftime("%Y-%m-%d")
          history_path = File.join(history_dir, "#{date}.jsonl")

          entry = {
            "time" => Time.now.utc.iso8601,
            "task" => task,
            "status" => result.status,
            "duration" => result.duration,
            "exit_code" => result.exit_code
          }

          File.open(history_path, "a") { |f| f.puts(entry.to_json) }
        end

        def state_file
          File.join(@state_dir, "last_run.yml")
        end

        def lock_file
          File.join(@state_dir, ".lock")
        end
      end
    end
  end
end
