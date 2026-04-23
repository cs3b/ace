# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Config
      module Molecules
        class SetupDoctorReporter
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
            doctor: "🏥",
            stats: "📊",
            success: "✅",
            error: "❌",
            warning: "⚠️",
            info: "ℹ️"
          }.freeze

          STATUS_GLYPHS = {
            "pass" => "✓",
            "warn" => "○",
            "blocker" => "✗",
            "skip" => "○",
            "info" => "○"
          }.freeze

          STATUS_COLORS = {
            "pass" => :green,
            "warn" => :yellow,
            "blocker" => :red,
            "skip" => :yellow,
            "info" => :cyan
          }.freeze

          def self.format_results(results, format: :terminal, hygiene: false, verbose: false, colors: true)
            case format.to_sym
            when :json
              JSON.pretty_generate(results)
            else
              new(results, hygiene: hygiene, verbose: verbose, colors: colors).format_terminal
            end
          end

          def initialize(results, hygiene:, verbose:, colors:)
            @results = results
            @hygiene = hygiene
            @verbose = verbose
            @colors = colors
          end

          def format_terminal
            output = []
            output << "\n#{colorize("#{ICONS[:doctor]} Setup Health Check", :bold)}"
            output << "=" * 40
            output.concat(format_overview)
            output.concat(format_readiness)
            output.concat(format_info)
            output.concat(format_provider_pings)
            output.concat(format_issues)
            output << "=" * 40
            output << format_summary_line
            output << "\n#{colorize("Completed in #{format_duration(@results[:duration])}", :blue)}" if @results[:duration]
            output << final_status_line
            output.join("\n")
          end

          private

          def format_overview
            stats = @results[:stats] || {}
            [
              "",
              colorize("#{ICONS[:stats]} Overview", :cyan),
              "-" * 20,
              "  Health checks: #{stats[:health_checks] || health_checks.length}",
              "  Info checks: #{stats[:info_checks] || info_checks.length}",
              "  Utility providers checked: #{stats[:provider_targets] || provider_outcomes.length}",
              "  Hygiene findings: #{stats[:hygiene_findings] || 0}"
            ]
          end

          def format_readiness
            rows = health_checks.reject { |check| check[:id] == "probe-readiness" }
            return [] if rows.empty?

            output = ["", colorize("Readiness", :cyan), "-" * 20]
            rows.each do |check|
              output << "  #{status_glyph(check[:status])} #{check[:message]}"
              if check[:status] == "blocker" || check[:status] == "warn" || @verbose
                Array(check[:details]).each { |detail| output << "    - #{detail}" }
                output << "    Next: #{check[:next_action]}" if check[:next_action]
              end
            end
            output
          end

          def format_info
            return [] if info_checks.empty?

            output = ["", colorize("Info", :cyan), "-" * 20]
            info_checks.each do |check|
              output << "  #{status_glyph(check[:status])} #{check[:message]}"
              if @verbose
                Array(check[:details]).each { |detail| output << "    - #{detail}" }
                output << "    Next: #{check[:next_action]}" if check[:next_action]
              end
            end
            output
          end

          def format_provider_pings
            check = health_checks.find { |row| row[:id] == "probe-readiness" }
            return [] unless check

            output = ["", colorize("Utility Provider Pings", :cyan), "-" * 20]
            output << "  #{status_glyph(check[:status])} #{check[:message]}"
            details = provider_outcomes.any? ? provider_outcomes.map { |outcome| provider_outcome_line(outcome) } : Array(check[:details])
            details.each { |detail| output << "    #{detail}" }
            output << "    Next: #{check[:next_action]}" if check[:next_action]
            output
          end

          def format_issues
            blockers = health_checks.select { |check| check[:status] == "blocker" }
            warnings = health_checks.select { |check| check[:status] == "warn" }
            hygiene_warnings = hygiene_checks.reject { |check| check[:status] == "pass" }

            if blockers.empty? && warnings.empty? && hygiene_warnings.empty?
              return ["", colorize("#{ICONS[:success]} No issues found", :green)]
            end

            output = ["", colorize("Issues Found:", :yellow), "-" * 20]
            output.concat(format_issue_group("#{ICONS[:error]} Blockers", blockers, :red, include_details: true))
            output.concat(format_issue_group("#{ICONS[:warning]} Warnings", warnings, :yellow, include_details: true))
            output.concat(format_hygiene_group(hygiene_warnings))
            output
          end

          def format_issue_group(title, checks, color, include_details:)
            return [] if checks.empty?

            output = ["", colorize("#{title} (#{checks.length})", color)]
            checks.each_with_index do |check, index|
              output << "#{index + 1}. #{check[:message]}"
              if include_details
                Array(check[:details]).each { |detail| output << "   - #{detail}" }
              end
              output << "   Next: #{check[:next_action]}" if check[:next_action]
            end
            output
          end

          def format_hygiene_group(checks)
            finding_count = @results.dig(:hygiene, :finding_count) || 0
            return [] if finding_count.zero?

            if !@hygiene && !@verbose
              return [
                "",
                colorize("#{ICONS[:warning]} Hygiene", :yellow),
                "1. Hygiene findings detected (#{finding_count}); rerun with --hygiene for details"
              ]
            end

            output = ["", colorize("#{ICONS[:warning]} Hygiene (#{finding_count})", :yellow)]
            issue_number = 1
            checks.each do |check|
              output << "#{issue_number}. #{check[:message]}"
              Array(check[:details]).each { |detail| output << "   - #{detail}" }
              output << "   Next: #{check[:next_action]}" if check[:next_action]
              issue_number += 1
            end
            output
          end

          def format_summary_line
            health = @results[:health] || {}
            hygiene = @results[:hygiene] || {}
            info = @results[:info] || {}
            parts = []
            parts << colorize("#{health[:blocker_count]} blockers", health[:blocker_count].to_i.positive? ? :red : :green)
            parts << colorize("#{health[:warning_count]} warnings", health[:warning_count].to_i.positive? ? :yellow : :green)
            parts << colorize("#{info[:count]} info", :cyan)
            parts << colorize("#{hygiene[:finding_count]} hygiene findings", hygiene[:finding_count].to_i.positive? ? :yellow : :green)
            parts.join(", ")
          end

          def final_status_line
            if @results[:valid]
              if @results.dig(:health, :warning_count).to_i.positive? || @results.dig(:hygiene, :finding_count).to_i.positive?
                colorize("Setup check passed with warnings", :yellow)
              else
                colorize("Setup check passed", :green)
              end
            else
              colorize("Setup check failed", :red)
            end
          end

          def provider_outcome_line(outcome)
            elapsed = outcome[:elapsed_ms] ? " in #{outcome[:elapsed_ms]}ms" : ""
            glyph = outcome[:status] == "pass" ? status_glyph(outcome[:status]) : colorize("✗", :red)
            suffix = if outcome[:status] == "pass"
              elapsed
            elsif outcome[:failure_type] == "timeout"
              " timed out after #{outcome[:timeout_seconds]}s"
            else
              " failed"
            end
            "#{glyph} #{target_display(outcome)}#{suffix}"
          end

          def target_display(target)
            label = target[:label].to_s
            selector = target[:selector].to_s
            label = selector if label.empty?
            selector.empty? || selector == label ? label : "#{label} (#{selector})"
          end

          def status_glyph(status)
            glyph = STATUS_GLYPHS.fetch(status.to_s, STATUS_GLYPHS["warn"])
            colorize(glyph, STATUS_COLORS.fetch(status.to_s, :yellow))
          end

          def health_checks
            @health_checks ||= checks.select { |check| check[:kind] == "health" }
          end

          def hygiene_checks
            @hygiene_checks ||= checks.select { |check| check[:kind] == "hygiene" }
          end

          def info_checks
            @info_checks ||= checks.select { |check| check[:kind] == "info" }
          end

          def provider_outcomes
            @provider_outcomes ||= Array(health_checks.find { |row| row[:id] == "probe-readiness" }&.fetch(:outcomes, []))
          end

          def checks
            @results[:checks] || []
          end

          def format_duration(duration)
            return "0ms" unless duration

            duration < 1 ? "#{(duration * 1000).round}ms" : "#{duration.round(2)}s"
          end

          def colorize(text, color)
            return text unless @colors && COLORS[color]

            "#{COLORS[color]}#{text}#{COLORS[:reset]}"
          end
        end
      end
    end
  end
end
