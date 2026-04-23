# frozen_string_literal: true

require "open3"

module Ace
  module Tmux
    module Molecules
      class LocalProcessInspector
        def initialize(command_runner: nil)
          @command_runner = command_runner || method(:run_command)
        end

        def find_descendant_command(root_pid, allowed_commands:)
          normalized_root = normalize_pid(root_pid)
          allowed = Array(allowed_commands).map { |command| normalize_command(command) }.reject(&:empty?)
          return nil if normalized_root.nil? || allowed.empty?

          queue = [normalized_root]
          visited = {}

          until queue.empty?
            parent_pid = queue.shift
            next if visited[parent_pid]

            visited[parent_pid] = true

            child_processes(parent_pid).each do |child|
              return child[:command] if allowed.include?(child[:command])

              queue << child[:pid]
            end
          end

          nil
        end

        private

        attr_reader :command_runner

        def child_processes(parent_pid)
          result = command_runner.call(["ps", "-o", "pid=,ppid=,comm=", "--ppid", parent_pid])
          return [] unless result[:success]

          result[:stdout].to_s.split("\n").map { |line| parse_process_line(line) }.compact
        rescue Errno::ENOENT
          []
        end

        def parse_process_line(line)
          pid, _ppid, command = line.to_s.strip.split(/\s+/, 3)
          return nil if pid.to_s.empty? || command.to_s.empty?

          {
            pid: normalize_pid(pid),
            command: normalize_command(command)
          }
        end

        def run_command(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          {
            success: status.success?,
            stdout: stdout,
            stderr: stderr
          }
        end

        def normalize_pid(value)
          candidate = value.to_s.strip
          return nil if candidate.empty?

          Integer(candidate).to_s
        rescue ArgumentError
          nil
        end

        def normalize_command(value)
          value.to_s.strip.downcase
        end
      end
    end
  end
end
