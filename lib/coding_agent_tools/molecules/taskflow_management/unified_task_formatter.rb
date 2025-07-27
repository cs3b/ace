# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # UnifiedTaskFormatter provides consistent task display formatting across all task commands
      class UnifiedTaskFormatter
        # Format a single task with optional modification time and position
        def self.format_task(task, options = {})
          verbose = options[:verbose] || false
          show_position = options[:position]
          show_time = options[:show_time] || false
          
          if verbose
            format_verbose(task, options)
          else
            format_compact(task, options)
          end
        end

        # Format multiple tasks
        def self.format_tasks(tasks, options = {})
          tasks.each_with_index do |task, index|
            task_options = options.dup
            task_options[:position] = index + 1 if options[:show_position]
            format_task(task, task_options)
          end
        end

        private

        def self.format_compact(task, options)
          title = task.title || extract_title_from_content(task)
          status = task.status.upcase
          
          # Add mtime to task if not present and show_time is requested
          if options[:show_time] && !task.respond_to?(:mtime) && File.exist?(task.path)
            mtime = File.mtime(task.path)
            task.define_singleton_method(:mtime) { mtime }
          end
          
          # Build main line components
          line_parts = []
          
          # Add position if requested
          if options[:position]
            line_parts << "#{options[:position].to_s.rjust(3)}."
          end
          
          # Core format: ID * STATUS * [TIME_AGO *] Title
          line_parts << task.id
          line_parts << status
          
          # Add modification time if available and requested
          if options[:show_time] && task.respond_to?(:mtime) && task.mtime
            line_parts << format_relative_time(task.mtime)
          end
          
          line_parts << title
          
          # Output main line
          puts line_parts.join(" * ")
          
          # Add path on next line if verbose positioning is used (for 'all' command compatibility)
          if options[:position] && options[:show_path]
            project_root = detect_project_root
            relative_path = task.path.sub(/^#{Regexp.escape(project_root)}\//, '')
            puts "     #{relative_path}"
          end
        end

        def self.format_verbose(task, options)
          # Add mtime to task if not present and show_time is requested
          if options[:show_time] && !task.respond_to?(:mtime) && File.exist?(task.path)
            mtime = File.mtime(task.path)
            task.define_singleton_method(:mtime) { mtime }
          end

          if options[:position]
            puts "#{options[:position].to_s.rjust(3)}. #{task.id}"
          elsif options[:task_number] && options[:total_tasks]
            puts "Task #{options[:task_number]}/#{options[:total_tasks]}:"
          end

          title = task.title || extract_title_from_content(task)
          puts verbose_line("Title", title)
          puts verbose_line("Status", task.status)
          puts verbose_line("Path", task.path)

          # Add modification time if available and requested
          if options[:show_time] && task.respond_to?(:mtime) && task.mtime
            puts verbose_line("Modified", format_relative_time(task.mtime))
          end

          if task.dependencies && !task.dependencies.empty?
            deps = task.dependencies.is_a?(Array) ? task.dependencies.join(", ") : task.dependencies
            puts verbose_line("Dependencies", deps)
          end

          if task.respond_to?(:estimate) && task.estimate
            puts verbose_line("Estimate", task.estimate)
          end

          if task.respond_to?(:priority) && task.priority
            puts verbose_line("Priority", task.priority.upcase)
          end
        end

        def self.verbose_line(label, value)
          prefix = label == "Title" ? "     " : "     "
          "#{prefix}#{label}: #{value}"
        end

        def self.format_relative_time(time)
          now = Time.now
          diff = now - time

          case diff
          when 0..3600
            hours = (diff / 3600).round
            hours == 0 ? "1 hour ago" : "#{hours} hours ago"
          when 3600..86400
            hours = (diff / 3600).round
            "#{hours} hours ago"
          when 86400..604800
            days = (diff / 86400).round
            "#{days} days ago"
          else
            # For more than a week, use short date format as requested
            time.strftime("%Y-%m-%d")
          end
        end

        def self.extract_title_from_content(task)
          return "Unknown" unless task.respond_to?(:content) && task.content

          # Look for first heading
          lines = task.content.split("\n")
          heading_line = lines.find { |line| line.start_with?("# ") }
          if heading_line
            heading_line.sub(/^# /, "").strip
          else
            "Unknown"
          end
        end

        def self.detect_project_root
          # Try to detect project root (fallback for path display)
          current_dir = Dir.pwd
          while current_dir != "/"
            return current_dir if File.exist?(File.join(current_dir, ".git"))
            current_dir = File.dirname(current_dir)
          end
          Dir.pwd
        end
      end
    end
  end
end