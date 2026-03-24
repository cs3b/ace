# frozen_string_literal: true

require "json"

module Ace
  module Retro
    module Molecules
      # Formats doctor diagnosis results for terminal, JSON, or summary output.
      class RetroDoctorReporter
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
          fix: "🔧",
          score: "📈"
        }.freeze

        # Format diagnosis results
        # @param results [Hash] Results from RetroDoctor#run_diagnosis
        # @param format [Symbol] Output format (:terminal, :json, :summary)
        # @param verbose [Boolean] Show verbose output
        # @param colors [Boolean] Enable colored output
        # @return [String] Formatted output
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

        # Format auto-fix results
        # @param fix_results [Hash] Results from RetroDoctorFixer#fix_issues
        # @param colors [Boolean] Enable colored output
        # @return [String] Formatted fix output
        def self.format_fix_results(fix_results, colors: true)
          output = []

          output << if fix_results[:dry_run]
            "\n#{colorize("#{ICONS[:stats]} DRY RUN MODE", :cyan, colors)} - No changes applied"
          else
            "\n#{colorize("#{ICONS[:fix]} Auto-Fix Applied", :green, colors)}"
          end

          if fix_results[:fixed] > 0
            output << "#{colorize("Fixed:", :green, colors)} #{fix_results[:fixed]} issues"

            if fix_results[:fixes_applied]&.any?
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

        class << self
          private

          def format_terminal(results, verbose: false, colors: true)
            output = []

            output << "\n#{colorize("#{ICONS[:doctor]} Retro Health Check", :bold, colors)}"
            output << "=" * 40

            if results[:stats]
              output << "\n#{colorize("#{ICONS[:stats]} Overview", :cyan, colors)}"
              output << "-" * 20
              output << "  Retros scanned: #{results[:stats][:retros_scanned]}"
              output << "  Folders checked: #{results[:stats][:folders_checked]}"
            end

            if results[:issues]&.any?
              output << "\n#{colorize("Issues Found:", :yellow, colors)}"
              output << "-" * 20
              output.concat(format_issues(results[:issues], verbose, colors))
            else
              output << "\n#{colorize("#{ICONS[:success]} All retros healthy", :green, colors)}"
            end

            output << "\n#{colorize("#{ICONS[:score]} Health Score:", :bold, colors)} #{format_health_score(results[:health_score], colors)}"
            output << "=" * 40

            if results[:stats]
              output << format_issue_summary(results[:stats], colors)
            end

            if results[:duration]
              output << "\n#{colorize("Completed in #{format_duration(results[:duration])}", :blue, colors)}"
            end

            output.join("\n")
          end

          def format_summary(results, colors: true)
            output = []

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

              output << colorize("Errors: #{errors}", :red, colors) if errors > 0
              output << colorize("Warnings: #{warnings}", :yellow, colors) if warnings > 0
            end

            output.join(" | ")
          end

          def format_json(results)
            clean = {
              health_score: results[:health_score],
              valid: results[:valid],
              errors: [],
              warnings: [],
              info: [],
              stats: results[:stats],
              duration: results[:duration],
              root_path: results[:root_path]
            }

            if results[:issues]
              results[:issues].each do |issue|
                category = case issue[:type]
                when :error then :errors
                when :warning then :warnings
                else :info
                end
                clean[category] << {
                  message: issue[:message],
                  location: issue[:location]
                }
              end
            end

            JSON.pretty_generate(clean)
          end

          def format_issues(issues, verbose, colors)
            output = []
            grouped = issues.group_by { |i| i[:type] }

            if grouped[:error]
              output << "\n#{colorize("#{ICONS[:error]} Errors (#{grouped[:error].size})", :red, colors)}"
              grouped[:error].each_with_index do |issue, i|
                output << format_issue(issue, i + 1, colors)
              end
            end

            if grouped[:warning]
              output << "\n#{colorize("#{ICONS[:warning]} Warnings (#{grouped[:warning].size})", :yellow, colors)}"
              if verbose || grouped[:warning].size <= 10
                grouped[:warning].each_with_index do |issue, i|
                  output << format_issue(issue, i + 1, colors)
                end
              else
                grouped[:warning].first(5).each_with_index do |issue, i|
                  output << format_issue(issue, i + 1, colors)
                end
                output << "  ... and #{grouped[:warning].size - 5} more warnings (use --verbose to see all)"
              end
            end

            output
          end

          def format_issue(issue, number, colors)
            location = issue[:location] ? " (#{colorize(issue[:location], :blue, colors)})" : ""
            "#{number}. #{issue[:message]}#{location}"
          end

          def format_health_score(score, colors)
            color = if score >= 90
              :green
            elsif score >= 70
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

          def format_issue_summary(stats, colors)
            parts = []
            parts << colorize("#{stats[:errors]} errors", :red, colors) if stats[:errors] > 0
            parts << colorize("#{stats[:warnings]} warnings", :yellow, colors) if stats[:warnings] > 0

            if parts.empty?
              colorize("No issues found", :green, colors)
            else
              parts.join(", ")
            end
          end

          def format_duration(duration)
            if duration < 1
              "#{(duration * 1000).round}ms"
            else
              "#{duration.round(2)}s"
            end
          end

          def colorize(text, color, enabled = true)
            return text unless enabled && COLORS[color]

            "#{COLORS[color]}#{text}#{COLORS[:reset]}"
          end
        end
      end
    end
  end
end
