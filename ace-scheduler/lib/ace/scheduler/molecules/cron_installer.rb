# frozen_string_literal: true

require "open3"

module Ace
  module Scheduler
    module Molecules
      class CronInstaller
        def initialize(config, builder: Atoms::CrontabBuilder.new)
          @config = config
          @builder = builder
        end

        def install(project_root: Dir.pwd)
          entries = build_entries(project_root: project_root)
          existing = read_crontab

          filtered = existing.reject { |line| line.include?("ace-scheduler") }
          new_entries = entries.map { |entry| "#{entry} # ace-scheduler" }
          new_content = (filtered + new_entries).join("\n") + "\n"

          write_crontab(new_content, fallback: existing.join("\n") + "\n")
        end

        def uninstall
          existing = read_crontab
          filtered = existing.reject { |line| line.include?("ace-scheduler") }
          write_crontab(filtered.join("\n") + "\n")
        end

        def status
          read_crontab.select { |line| line.include?("ace-scheduler") }
        end

        private

        def build_entries(project_root:)
          tasks = @config[:tasks] || {}
          tasks.map do |name, task|
            next unless task[:enabled]

            @builder.build_entry(
              cron: task[:cron],
              task_name: name,
              command: task[:command],
              project_root: project_root
            )
          end.compact
        end

        def read_crontab
          stdout, _stderr, status = Open3.capture3("crontab", "-l")
          return [] unless status.success?

          stdout.lines.map(&:chomp)
        end

        def write_crontab(content, fallback: nil)
          _stdout, _stderr, status = Open3.capture3("crontab", "-", stdin_data: content)
          return if status.success?

          if fallback
            Open3.capture3("crontab", "-", stdin_data: fallback)
          end

          raise Ace::Scheduler::Error, "Failed to update crontab"
        end
      end
    end
  end
end
