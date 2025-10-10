# frozen_string_literal: true

require "json"

module Ace
  module Taskflow
    module Molecules
      # Handles formatting and reporting of doctor results
      class DoctorReporter
        COLORS = {
          red: "\e[31m",
          yellow: "\e[33m",
          green: "\e[32m",
          blue: "\e[34m",
          cyan: "\e[36m",
          reset: "\e[0m",
          bold: "\e[1m"
        }.freeze

        ICONS = {
          error: "❌",
          warning: "⚠️",
          info: "ℹ️",
          success: "✅",
          doctor: "🏥",
          stats: "📊",
          search: "🔍",
          fix: "🔧",
          score: "📈"
        }.freeze

        def self.format_results(results, format: :terminal, verbose: false, colors: true)
          case format.to_sym
          when :json
            format_json(results)
          when :summary
            format_summary(results, colors: colors)
          else
            format_terminal(results, verbose: verbose, colors: colors)
          end
        end

        def self.format_fix_results(fix_results, colors: true)
          output = []

          if fix_results[:dry_run]
            output << "\n#{colorize("🔍 DRY RUN MODE", :cyan, colors)} - No changes applied"
          else
            output << "\n#{colorize("#{ICONS[:fix]} Auto-Fix Applied", :green, colors)}"
          end

          if fix_results[:fixed] > 0
            output << "#{colorize("Fixed:", :green, colors)} #{fix_results[:fixed]} issues"

            if fix_results[:fixes_applied] && fix_results[:fixes_applied].any?
              output << "\nFixes applied:"
              fix_results[:fixes_applied].each do |fix|
                output << "  #{colorize("✓", :green, colors)} #{fix[:description]}"
                output << "    #{colorize(fix[:file], :blue, colors)}" if fix[:file]
              end
            end
          end

          if fix_results[:skipped] > 0
            output << "#{colorize("Skipped:", :yellow, colors)} #{fix_results[:skipped]} issues (manual fix required)"
          end

          output.join("\n")
        end

        private

        def self.format_terminal(results, verbose: false, colors: true)
          output = []

          # Header
          output << "\n#{colorize("#{ICONS[:doctor]} Taskflow Health Check", :bold, colors)}"
          output << "=" * 40

          # System overview
          if results[:stats] && results[:stats][:components]
            output << "\n#{colorize("#{ICONS[:stats]} System Overview", :cyan, colors)}"
            output << "-" * 20
            output.concat(format_system_stats(results[:stats][:components], colors))
          end

          # Progress/Scanning info
          if results[:stats][:files_scanned] > 0
            output << "\n#{colorize("#{ICONS[:search]} Scanning Results", :cyan, colors)}"
            output << "Files scanned: #{results[:stats][:files_scanned]}"
          end

          # Issues
          if results[:issues] && results[:issues].any?
            output << "\n#{colorize("Issues Found:", :yellow, colors)}"
            output << "-" * 20
            output.concat(format_issues(results[:issues], verbose, colors))
          else
            output << "\n#{colorize("#{ICONS[:success]} All components healthy", :green, colors)}"
          end

          # Health Score
          output << "\n#{colorize("#{ICONS[:score]} Health Score:", :bold, colors)} #{format_health_score(results[:health_score], colors)}"
          output << "=" * 40

          # Summary
          if results[:stats]
            output << format_issue_summary(results[:stats], colors)
          end

          # Duration
          if results[:duration]
            output << "\n#{colorize("Completed in #{format_duration(results[:duration])}", :blue, colors)}"
          end

          output.join("\n")
        end

        def self.format_summary(results, colors: true)
          output = []

          # Quick summary
          health_status = if results[:health_score] >= 90
                           colorize("Excellent", :green, colors)
                         elsif results[:health_score] >= 70
                           colorize("Good", :yellow, colors)
                         elsif results[:health_score] >= 50
                           colorize("Fair", :yellow, colors)
                         else
                           colorize("Poor", :red, colors)
                         end

          output << "Health: #{health_status} (#{results[:health_score]}/100)"

          if results[:stats]
            errors = results[:stats][:errors] || 0
            warnings = results[:stats][:warnings] || 0
            info = results[:stats][:info] || 0

            if errors > 0
              output << colorize("Errors: #{errors}", :red, colors)
            end
            if warnings > 0
              output << colorize("Warnings: #{warnings}", :yellow, colors)
            end
            if info > 0 && errors == 0 && warnings == 0
              output << colorize("Info: #{info}", :blue, colors)
            end
          end

          output.join(" | ")
        end

        def self.format_json(results)
          # Clean up for JSON output
          clean_results = {
            health_score: results[:health_score],
            valid: results[:valid],
            errors: [],
            warnings: [],
            info: [],
            stats: results[:stats]
          }

          if results[:issues]
            results[:issues].each do |issue|
              category = case issue[:type]
                        when :error then :errors
                        when :warning then :warnings
                        else :info
                        end

              clean_results[category] << {
                message: issue[:message],
                location: issue[:location]
              }
            end
          end

          JSON.pretty_generate(clean_results)
        end

        def self.format_system_stats(components, colors)
          output = []

          if components[:structure]
            s = components[:structure]
            if s[:releases]
              output << "  Releases: #{s[:releases][:active]} active | #{s[:releases][:backlog]} backlog | #{s[:releases][:done]} done"
            end
            if s[:tasks]
              output << "  Tasks: #{s[:tasks][:total]} total"
            end
            if s[:ideas]
              output << "  Ideas: #{s[:ideas][:total]} total"
            end
          end

          if components[:integrity]
            i = components[:integrity]
            output << "  Components validated: #{i[:tasks]} tasks, #{i[:ideas]} ideas, #{i[:releases]} releases"
          end

          output
        end

        def self.format_issues(issues, verbose, colors)
          output = []

          # Group issues by type
          grouped = issues.group_by { |i| i[:type] }

          # Show errors first
          if grouped[:error]
            output << "\n#{colorize("#{ICONS[:error]} Critical Issues (#{grouped[:error].size})", :red, colors)}"
            grouped[:error].each_with_index do |issue, i|
              output << format_issue(issue, i + 1, colors)
            end
          end

          # Show warnings
          if grouped[:warning]
            output << "\n#{colorize("#{ICONS[:warning]} Warnings (#{grouped[:warning].size})", :yellow, colors)}"
            if verbose || grouped[:warning].size <= 10
              grouped[:warning].each_with_index do |issue, i|
                output << format_issue(issue, i + 1, colors)
              end
            else
              # Show first 5 warnings
              grouped[:warning].first(5).each_with_index do |issue, i|
                output << format_issue(issue, i + 1, colors)
              end
              output << "  ... and #{grouped[:warning].size - 5} more warnings (use --verbose to see all)"
            end
          end

          # Show info (only in verbose mode)
          if verbose && grouped[:info]
            output << "\n#{colorize("#{ICONS[:info]} Information (#{grouped[:info].size})", :blue, colors)}"
            grouped[:info].each_with_index do |issue, i|
              output << format_issue(issue, i + 1, colors)
            end
          end

          output
        end

        def self.format_issue(issue, number, colors)
          location = issue[:location] ? " (#{colorize(issue[:location], :blue, colors)})" : ""
          "#{number}. #{issue[:message]}#{location}"
        end

        def self.format_health_score(score, colors)
          color = if score >= 90
                   :green
                 elsif score >= 70
                   :yellow
                 elsif score >= 50
                   :yellow
                 else
                   :red
                 end

          status = if score >= 90
                    "Excellent"
                  elsif score >= 70
                    "Good"
                  elsif score >= 50
                    "Fair"
                  else
                    "Poor"
                  end

          "#{colorize("#{score}/100", color, colors)} (#{status})"
        end

        def self.format_issue_summary(stats, colors)
          parts = []

          if stats[:errors] > 0
            parts << colorize("#{stats[:errors]} errors", :red, colors)
          end

          if stats[:warnings] > 0
            parts << colorize("#{stats[:warnings]} warnings", :yellow, colors)
          end

          if stats[:info] > 0
            parts << colorize("#{stats[:info]} info", :blue, colors)
          end

          if parts.empty?
            colorize("No issues found", :green, colors)
          else
            parts.join(", ")
          end
        end

        def self.format_duration(duration)
          if duration < 1
            "#{(duration * 1000).round}ms"
          else
            "#{duration.round(2)}s"
          end
        end

        def self.colorize(text, color, enabled = true)
          return text unless enabled && COLORS[color]

          "#{COLORS[color]}#{text}#{COLORS[:reset]}"
        end

        # Format progress bar for scanning
        def self.format_progress(current, total, width = 40)
          return "" if total == 0

          percentage = (current.to_f / total * 100).round
          filled = (width * (current.to_f / total)).round
          bar = "█" * filled + "░" * (width - filled)

          "\r[#{bar}] #{percentage}% (#{current}/#{total})"
        end
      end
    end
  end
end