# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Filter tasks by various criteria
      class TaskFilter
        # Filter tasks by status
        # @param tasks [Array<Hash>] Tasks to filter
        # @param statuses [Array<String>] Statuses to include
        # @return [Array<Hash>] Filtered tasks
        def self.filter_by_status(tasks, statuses)
          return tasks if statuses.nil? || statuses.empty?

          normalized_statuses = statuses.map(&:downcase)
          tasks.select do |task|
            normalized_statuses.include?(task[:status].to_s.downcase)
          end
        end

        # Filter tasks by priority
        # @param tasks [Array<Hash>] Tasks to filter
        # @param priorities [Array<String>] Priorities to include
        # @return [Array<Hash>] Filtered tasks
        def self.filter_by_priority(tasks, priorities)
          return tasks if priorities.nil? || priorities.empty?

          normalized_priorities = priorities.map(&:downcase)
          tasks.select do |task|
            normalized_priorities.include?(task[:priority].to_s.downcase)
          end
        end

        # Filter tasks by release/context
        # @param tasks [Array<Hash>] Tasks to filter
        # @param context [String] Context to filter by
        # @return [Array<Hash>] Filtered tasks
        def self.filter_by_context(tasks, context)
          return tasks if context.nil? || context.empty?

          tasks.select do |task|
            task[:context] == context
          end
        end

        # Filter tasks by dependency status
        # @param tasks [Array<Hash>] Tasks to filter
        # @param has_dependencies [Boolean] True for tasks with dependencies
        # @return [Array<Hash>] Filtered tasks
        def self.filter_by_dependencies(tasks, has_dependencies)
          if has_dependencies
            tasks.select { |task| !task[:dependencies].empty? }
          else
            tasks.select { |task| task[:dependencies].empty? }
          end
        end

        # Filter tasks modified within a time range
        # @param tasks [Array<Hash>] Tasks to filter
        # @param days [Integer] Number of days to look back
        # @return [Array<Hash>] Filtered tasks
        def self.filter_recent(tasks, days)
          return tasks if days.nil? || days <= 0

          cutoff_time = Time.now - (days * 24 * 60 * 60)

          tasks.select do |task|
            if task[:path] && File.exist?(task[:path])
              File.mtime(task[:path]) >= cutoff_time
            else
              false
            end
          end
        end

        # Apply multiple filters
        # @param tasks [Array<Hash>] Tasks to filter
        # @param filters [Hash] Filter criteria
        # @return [Array<Hash>] Filtered tasks
        def self.apply_filters(tasks, filters = {})
          result = tasks

          # Apply status filter
          if filters[:status]
            statuses = Array(filters[:status])
            result = filter_by_status(result, statuses)
          end

          # Apply priority filter
          if filters[:priority]
            priorities = Array(filters[:priority])
            result = filter_by_priority(result, priorities)
          end

          # Apply context filter
          if filters[:context]
            result = filter_by_context(result, filters[:context])
          end

          # Apply dependency filter
          unless filters[:has_dependencies].nil?
            result = filter_by_dependencies(result, filters[:has_dependencies])
          end

          # Apply recent filter
          if filters[:recent_days]
            result = filter_recent(result, filters[:recent_days])
          end

          result
        end

        # Sort tasks by various criteria
        # @param tasks [Array<Hash>] Tasks to sort
        # @param sort_by [Symbol] Sort criterion
        # @param ascending [Boolean] Sort direction
        # @return [Array<Hash>] Sorted tasks
        def self.sort_tasks(tasks, sort_by = :id, ascending = true)
          sorted = case sort_by
          when :priority
            tasks.sort_by { |t| priority_value(t[:priority]) }
          when :status
            tasks.sort_by { |t| status_value(t[:status]) }
          when :id
            tasks.sort_by { |t| t[:id] || "" }
          when :modified
            tasks.sort_by do |t|
              if t[:path] && File.exist?(t[:path])
                File.mtime(t[:path])
              else
                Time.at(0)
              end
            end
          when :estimate
            tasks.sort_by { |t| parse_estimate(t[:estimate]) }
          else
            tasks
          end

          ascending ? sorted : sorted.reverse
        end

        # Check if task matches filter string
        # @param task [Hash] Task to check
        # @param filter_string [String] Filter string (e.g., "status:pending")
        # @return [Boolean] True if matches
        def self.matches_filter_string?(task, filter_string)
          return true if filter_string.nil? || filter_string.empty?

          # Parse filter string
          if match = filter_string.match(/^(\w+):(.+)$/)
            field = match[1].downcase
            value = match[2].downcase

            # Handle negation
            if value.start_with?("!")
              value = value[1..-1]
              negate = true
            else
              negate = false
            end

            # Check field
            result = case field
            when "status"
              task[:status].to_s.downcase == value
            when "priority"
              task[:priority].to_s.downcase == value
            when "context"
              task[:context].to_s.downcase == value
            when "has_dependencies"
              value == "true" ? !task[:dependencies].empty? : task[:dependencies].empty?
            else
              false
            end

            negate ? !result : result
          else
            # Search in title and content
            search_term = filter_string.downcase
            task[:title].to_s.downcase.include?(search_term) ||
              task[:content].to_s.downcase.include?(search_term)
          end
        end

        private

        def self.priority_value(priority)
          case priority.to_s.downcase
          when "critical" then 0
          when "high" then 1
          when "medium" then 2
          when "low" then 3
          else 4
          end
        end

        def self.status_value(status)
          case status.to_s.downcase
          when "done" then 0
          when "in-progress" then 1
          when "pending" then 2
          when "blocked" then 3
          else 4
          end
        end

        def self.parse_estimate(estimate)
          return 999 if estimate.nil? || estimate.empty?

          # Parse estimates like "3d", "4h", "2w"
          if match = estimate.match(/^(\d+)([dhw])$/i)
            value = match[1].to_i
            unit = match[2].downcase

            case unit
            when "h" then value
            when "d" then value * 8
            when "w" then value * 40
            else value
            end
          else
            999
          end
        end
      end
    end
  end
end