# frozen_string_literal: true

require "time"

module CodingAgentTools
  module Molecules
    module Search
      # Filters files based on modification time
      class TimeFilter
        # Common time expressions
        TIME_PATTERNS = {
          /^(\d+)\s*(second|sec|s)s?\s*ago$/i => :seconds,
          /^(\d+)\s*(minute|min|m)s?\s*ago$/i => :minutes,
          /^(\d+)\s*(hour|hr|h)s?\s*ago$/i => :hours,
          /^(\d+)\s*(day|d)s?\s*ago$/i => :days,
          /^(\d+)\s*(week|w)s?\s*ago$/i => :weeks,
          /^(\d+)\s*(month|mon)s?\s*ago$/i => :months,
          /^(\d+)\s*(year|yr|y)s?\s*ago$/i => :years,
          /^yesterday$/i => :yesterday,
          /^today$/i => :today,
          /^this\s*week$/i => :this_week,
          /^last\s*week$/i => :last_week,
          /^this\s*month$/i => :this_month,
          /^last\s*month$/i => :last_month
        }.freeze

        # Initialize time filter
        def initialize
          @now = Time.now
        end

        # Filter files by modification time
        # @param files [Array<String>] File paths to filter
        # @param since [String, Time, nil] Filter files modified since this time
        # @param before [String, Time, nil] Filter files modified before this time
        # @return [Array<String>] Filtered file paths
        def filter_files(files, since: nil, before: nil)
          since_time = parse_time_expression(since) if since
          before_time = parse_time_expression(before) if before
          
          files.select do |file|
            next false unless File.exist?(file)
            
            mtime = File.mtime(file)
            
            # Check since constraint
            next false if since_time && mtime < since_time
            
            # Check before constraint
            next false if before_time && mtime > before_time
            
            true
          end
        end

        # Parse time expression into Time object
        # @param expression [String, Time] Time expression or Time object
        # @return [Time, nil] Parsed time or nil if invalid
        def parse_time_expression(expression)
          return expression if expression.is_a?(Time)
          return nil unless expression.is_a?(String)
          
          # Try to parse as absolute time
          begin
            return Time.parse(expression)
          rescue ArgumentError
            # Not a parseable time, try patterns
          end
          
          # Try relative time patterns
          TIME_PATTERNS.each do |pattern, type|
            match = expression.match(pattern)
            next unless match
            
            return calculate_relative_time(type, match[1]&.to_i)
          end
          
          nil
        end

        # Generate fd/ripgrep time filter arguments
        # @param since [String, Time, nil] Since time expression
        # @param before [String, Time, nil] Before time expression
        # @return [Array<String>] Command-line arguments for fd
        def generate_fd_args(since: nil, before: nil)
          args = []
          
          if since
            since_time = parse_time_expression(since)
            if since_time
              # fd uses --changed-within for files modified recently
              duration = format_duration_for_fd(@now - since_time)
              args << "--changed-within" << duration
            end
          end
          
          if before
            before_time = parse_time_expression(before)
            if before_time
              # fd uses --changed-before for older files
              duration = format_duration_for_fd(@now - before_time)
              args << "--changed-before" << duration
            end
          end
          
          args
        end

        # Get file modification info
        # @param file [String] File path
        # @return [Hash] File time information
        def file_time_info(file)
          return {} unless File.exist?(file)
          
          stat = File.stat(file)
          mtime = stat.mtime
          
          {
            path: file,
            modified: mtime,
            modified_relative: format_relative_time(mtime),
            modified_iso: mtime.iso8601,
            age_seconds: (@now - mtime).to_i
          }
        end

        private

        # Calculate relative time from type and amount
        def calculate_relative_time(type, amount)
          case type
          when :seconds
            @now - amount
          when :minutes
            @now - (amount * 60)
          when :hours
            @now - (amount * 3600)
          when :days
            @now - (amount * 86400)
          when :weeks
            @now - (amount * 604800)
          when :months
            @now - (amount * 2592000) # Approximate
          when :years
            @now - (amount * 31536000)
          when :yesterday
            @now - 86400
          when :today
            Time.new(@now.year, @now.month, @now.day)
          when :this_week
            @now - (@now.wday * 86400)
          when :last_week
            @now - ((@now.wday + 7) * 86400)
          when :this_month
            Time.new(@now.year, @now.month, 1)
          when :last_month
            last_month = @now.month == 1 ? 12 : @now.month - 1
            last_year = @now.month == 1 ? @now.year - 1 : @now.year
            Time.new(last_year, last_month, 1)
          else
            nil
          end
        end

        # Format duration for fd command
        def format_duration_for_fd(seconds)
          seconds = seconds.to_i
          
          if seconds < 60
            "#{seconds}s"
          elsif seconds < 3600
            "#{seconds / 60}m"
          elsif seconds < 86400
            "#{seconds / 3600}h"
          elsif seconds < 604800
            "#{seconds / 86400}d"
          else
            "#{seconds / 604800}w"
          end
        end

        # Format relative time for display
        def format_relative_time(time)
          diff = (@now - time).to_i
          
          case diff
          when 0..59
            "#{diff} seconds ago"
          when 60..3599
            "#{diff / 60} minutes ago"
          when 3600..86399
            "#{diff / 3600} hours ago"
          when 86400..604799
            "#{diff / 86400} days ago"
          else
            "#{diff / 604800} weeks ago"
          end
        end
      end
    end
  end
end