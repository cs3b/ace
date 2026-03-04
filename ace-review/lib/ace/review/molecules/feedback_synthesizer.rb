# frozen_string_literal: true

require "json"
require "fileutils"
require "ace/support/items/atoms/tmp_workspace"

module Ace
  module Review
    module Molecules
      # Synthesizes feedback items from multiple review reports.
      #
      # Reads ALL reports in a single LLM pass and outputs deduplicated
      # FeedbackItems with reviewer arrays tracking which models found each issue.
      #
      # @example Basic usage
      #   synthesizer = FeedbackSynthesizer.new
      #   result = synthesizer.synthesize(
      #     report_paths: [
      #       "session/review-report-gemini-2.5-flash.md",
      #       "session/review-report-claude-3.5-sonnet.md",
      #       "session/review-report-gpt-4.md"
      #     ],
      #     session_dir: "session"
      #   )
      #   result[:success] #=> true
      #   result[:items]   #=> [FeedbackItem, ...] (with reviewers arrays)
      #
      class FeedbackSynthesizer
        # Maximum combined report size before truncation (characters)
        MAX_COMBINED_SIZE = 200_000

        attr_reader :llm_executor

        def initialize(llm_executor: nil)
          @llm_executor = llm_executor || LlmExecutor.new
        end

        # Synthesize feedback items from review reports
        #
        # Unified process that handles single or multiple reports:
        # - Single report: extracts findings directly
        # - Multiple reports: deduplicates and tracks consensus across reviewers
        #
        # @param report_paths [Array<String>] Paths to review report files
        # @param session_dir [String, nil] Session directory for LLM output files
        # @param model [String, nil] Model to use for synthesis (default: config setting)
        # @return [Hash] Result with :success, :items, :metadata or :error
        def synthesize(report_paths:, session_dir: nil, model: nil)
          # Validate inputs
          return error_result("No report paths provided") if report_paths.nil? || report_paths.empty?

          # Create session dir if needed
          session_dir ||= create_temp_session_dir
          FileUtils.mkdir_p(session_dir) unless Dir.exist?(session_dir)

          # Read all reports
          reports = read_reports(report_paths)
          return error_result("No valid reports found") if reports.empty?

          # Synthesize (handles both single and multiple reports uniformly)
          synthesize_reports(reports, session_dir, model)
        rescue StandardError => e
          error_result("Synthesis failed: #{e.message}", backtrace: e.backtrace.first(5))
        end

        private

        # Read multiple report files
        #
        # @param report_paths [Array<String>] Paths to report files
        # @return [Array<Hash>] Array of report hashes with :path, :reviewer, :content
        def read_reports(report_paths)
          reports = []

          report_paths.each do |path|
            next unless File.exist?(path)

            content = File.read(path)
            next if content.strip.empty?

            reviewer = extract_reviewer_from_filename(path)
            reports << {
              path: path,
              reviewer: reviewer,
              content: content,
              size: content.bytesize
            }
          rescue StandardError => e
            warn "Warning: Failed to read report #{path}: #{e.message}" if Ace::Review.debug?
          end

          reports
        end

        # Synthesize reports into unified findings
        #
        # Handles both single and multiple reports uniformly:
        # - Single report: extracts findings directly (no deduplication needed)
        # - Multiple reports: deduplicates and tracks consensus across reviewers
        #
        # @param reports [Array<Hash>] Array of report data
        # @param session_dir [String] Session directory
        # @param model [String, nil] Model to use
        # @return [Hash] Result with :success, :items, :metadata or :error
        def synthesize_reports(reports, session_dir, model)
          system_prompt = load_system_prompt
          user_prompt = build_reports_prompt(reports)

          output_file = File.join(session_dir, "feedback-synthesis.json")

          display_synthesis_start(reports.size, model || default_synthesis_model)

          result = @llm_executor.execute(
            system_prompt: system_prompt,
            user_prompt: user_prompt,
            model: model || default_synthesis_model,
            session_dir: session_dir,
            output_file: output_file
          )

          unless result[:success]
            return error_result("LLM synthesis failed: #{result[:error]}")
          end

          # All reviewers for reference
          all_reviewers = reports.map { |r| r[:reviewer] }

          parse_synthesis_response(result[:response], all_reviewers)
        end

        # Load the synthesis system prompt
        #
        # @return [String] System prompt content
        def load_system_prompt
          prompt_name = "synthesize-feedback.system.md"
          prompt_path = resolve_prompt_path(prompt_name)

          if File.exist?(prompt_path)
            File.read(prompt_path)
          else
            fallback_synthesis_prompt
          end
        end

        # Fallback synthesis prompt (used when prompt file not found)
        #
        # @return [String] Basic synthesis prompt
        def fallback_synthesis_prompt
          <<~PROMPT
            Synthesize feedback from code review reports into unique findings.

            For each unique issue found:
            1. Track which reviewers identified it (by their model names)
            2. Merge file references from all sources
            3. Use the most comprehensive description
            4. Mark consensus=true if 3+ reviewers agree

            Return valid JSON with this schema:
            {
              "findings": [
                {
                  "title": "Short title (max 60 chars)",
                  "files": ["path/file.rb:10-20"],
                  "reviewers": ["gemini-2.5-flash", "claude-3.5-sonnet"],
                  "consensus": false,
                  "priority": "high|medium|low|critical",
                  "finding": "Description of the issue",
                  "context": "Why this matters"
                }
              ]
            }

            IMPORTANT:
            - When only one report: extract all findings as-is with that reviewer
            - When multiple reports: deduplicate findings that describe the same issue
            - When multiple reviewers find the same issue, list ALL of them in reviewers array
            - Merge file arrays from all sources for each finding
            - Return ONLY the JSON, no markdown code fences
          PROMPT
        end

        # Build user prompt for report synthesis
        #
        # @param reports [Array<Hash>] Array of report data
        # @return [String] User prompt
        def build_reports_prompt(reports)
          # Check total size
          total_size = reports.sum { |r| r[:size] }

          content = "Synthesize these #{reports.size} code review report"
          content += reports.size == 1 ? "." : "s into unique, deduplicated findings."
          content += "\n\n"
          content += "**Reviewers**: #{reports.map { |r| r[:reviewer] }.join(', ')}\n\n"

          reports.each_with_index do |report, idx|
            content += "---\n"
            content += "## Report #{idx + 1}: #{report[:reviewer]}\n\n"

            # Truncate individual reports if total is too large
            report_content = report[:content]
            if total_size > MAX_COMBINED_SIZE
              max_per_report = MAX_COMBINED_SIZE / reports.size
              if report_content.length > max_per_report
                report_content = report_content[0, max_per_report] + "\n\n[... truncated ...]"
              end
            end

            content += report_content
            content += "\n\n"
          end

          content += "---\n\n"
          content += "Identify unique findings across all reports. Track which reviewers found each issue."

          content
        end

        # Parse the LLM synthesis response
        #
        # @param response [String] LLM response (should be JSON)
        # @param available_reviewers [Array<String>] List of available reviewers
        # @return [Hash] Result with :success, :items, :metadata or :error
        def parse_synthesis_response(response, available_reviewers)
          cleaned = extract_json_from_response(response)
          data = JSON.parse(cleaned)
          findings = data["findings"] || []

          # Pre-generate unique sequential IDs for all findings
          # This ensures uniqueness even when items are created in rapid succession
          ids = findings.empty? ? [] : Atoms::FeedbackIdGenerator.generate_sequence(findings.length)

          items = findings.each_with_index.filter_map do |finding, idx|
            create_feedback_item(finding, available_reviewers, id: ids[idx])
          end

          metadata = {
            total_findings: items.length,
            consensus_findings: items.count(&:consensus),
            reviewers_count: available_reviewers.length
          }

          display_synthesis_complete(items.length, metadata[:consensus_findings])

          { success: true, items: items, metadata: metadata }
        rescue JSON::ParserError => e
          error_result("Invalid JSON response: #{e.message}")
        end

        # Extract JSON from LLM response
        #
        # Handles various response formats:
        # - Pure JSON
        # - JSON wrapped in markdown code fences
        # - Text before/after code fences (e.g., "Based on my analysis...\n```json\n{...}\n```")
        # - JSON object embedded in text without fences
        #
        # @param response [String] Raw LLM response
        # @return [String] Extracted JSON string
        def extract_json_from_response(response)
          cleaned = response.to_s.strip

          # Try to extract JSON from markdown code fence (handles text before/after fence)
          if (match = cleaned.match(/```(?:json)?\s*(.*?)\s*```/m))
            return match[1].strip
          end

          # No code fence - try to find JSON object directly
          # This handles cases where JSON is embedded in text without fences
          if cleaned !~ /\A\s*\{/ && (json_match = cleaned.match(/(\{.*\})/m))
            return json_match[1]
          end

          # Return as-is (already clean JSON or will fail parsing with clear error)
          cleaned
        end

        # Create a FeedbackItem from synthesized finding data
        #
        # @param finding [Hash] Synthesized finding data
        # @param available_reviewers [Array<String>] List of available reviewers
        # @param id [String, nil] Pre-generated ID (optional, generates new if nil)
        # @return [FeedbackItem, nil] Created item or nil if invalid
        def create_feedback_item(finding, available_reviewers, id: nil)
          # Skip findings without required fields
          return nil if finding["title"].nil? || finding["title"].to_s.strip.empty?
          return nil if finding["finding"].nil? || finding["finding"].to_s.strip.empty?

          # Use provided ID or generate a new one
          id ||= Atoms::FeedbackIdGenerator.generate

          # Normalize priority
          priority = normalize_priority(finding["priority"])

          # Extract reviewers - either from finding or use all available
          reviewers = extract_reviewers(finding, available_reviewers)

          # Determine consensus
          consensus = finding["consensus"] == true || reviewers.length >= Models::FeedbackItem::CONSENSUS_THRESHOLD

          Models::FeedbackItem.new(
            id: id,
            title: finding["title"].to_s.strip[0, 60],  # Enforce max length
            files: Array(finding["files"]).map(&:to_s).uniq,
            reviewers: reviewers,
            status: "draft",
            priority: priority,
            consensus: consensus,
            finding: finding["finding"].to_s.strip,
            context: finding["context"]&.to_s&.strip
          )
        rescue ArgumentError => e
          warn "Warning: Failed to create FeedbackItem: #{e.message}" if Ace::Review.debug?
          nil
        end

        # Extract reviewers from finding or use available reviewers
        #
        # @param finding [Hash] Finding data
        # @param available_reviewers [Array<String>] All available reviewers
        # @return [Array<String>] Normalized reviewer list
        def extract_reviewers(finding, available_reviewers)
          if finding["reviewers"].is_a?(Array) && finding["reviewers"].any?
            # Normalize reviewer names from LLM output
            finding["reviewers"].map do |r|
              normalize_reviewer_name(r.to_s, available_reviewers)
            end.compact.uniq
          elsif finding["reviewer"]
            # Single reviewer (legacy format)
            [normalize_reviewer_name(finding["reviewer"].to_s, available_reviewers)].compact
          elsif available_reviewers.length == 1
            # Single-report case
            available_reviewers
          else
            # Unknown - use empty array
            []
          end
        end

        # Normalize reviewer name to match available reviewers
        #
        # @param name [String] Reviewer name from LLM output
        # @param available_reviewers [Array<String>] Available reviewer names
        # @return [String, nil] Matched reviewer or original name
        def normalize_reviewer_name(name, available_reviewers)
          return nil if name.empty?

          # Try exact match
          return name if available_reviewers.include?(name)

          # Try case-insensitive match
          match = available_reviewers.find { |r| r.downcase == name.downcase }
          return match if match

          # Try partial match (LLM might output "gemini" instead of "google:gemini-2.5-flash")
          match = available_reviewers.find { |r| r.downcase.include?(name.downcase) }
          return match if match

          # Return original if no match (might be a valid new reviewer)
          name
        end

        # Normalize priority value
        #
        # @param priority [String, nil] Input priority
        # @return [String] Valid priority value
        def normalize_priority(priority)
          valid = %w[critical high medium low]
          normalized = priority.to_s.downcase.strip
          valid.include?(normalized) ? normalized : "medium"
        end

        # Extract reviewer identifier from report filename
        #
        # @param path [String] Report file path
        # @return [String] Reviewer identifier
        def extract_reviewer_from_filename(path)
          basename = File.basename(path, ".md")

          case basename
          when "review-dev-feedback"
            "developer"
          when "synthesis-report"
            "synthesis"
          when /^review-report-(.+)$/
            model_name = Regexp.last_match(1)
            infer_provider_prefix(model_name)
          when /^review-(.+)$/
            model_name = Regexp.last_match(1)
            infer_provider_prefix(model_name)
          else
            basename
          end
        end

        # Infer provider prefix from model name
        #
        # @param model_name [String] Model name without provider
        # @return [String] Full model identifier with provider prefix
        def infer_provider_prefix(model_name)
          case model_name
          when /^gemini/i
            "google:#{model_name}"
          when /^gpt/i, /^o1/i
            "openai:#{model_name}"
          when /^claude/i
            "anthropic:#{model_name}"
          else
            model_name
          end
        end

        # Resolve prompt path
        #
        # @param prompt_name [String] Prompt filename
        # @return [String] Resolved file path
        def resolve_prompt_path(prompt_name)
          # Try ace-nav first if available
          nav_result = `ace-nav prompt://#{prompt_name} 2>/dev/null`.strip rescue ""
          return nav_result unless nav_result.empty?

          # Fallback to direct path
          File.join(__dir__, "../../../../handbook/prompts", prompt_name)
        end

        # Get default synthesis model from config
        #
        # @return [String] Default model identifier
        def default_synthesis_model
          Ace::Review.get("feedback", "synthesis_model") ||
            Ace::Review.get("defaults", "model") ||
            "google:gemini-2.5-flash"
        end

        # Create temporary session directory
        #
        # @return [String] Temp directory path
        def create_temp_session_dir
          Ace::Support::Items::Atoms::TmpWorkspace.create("feedback-synthesis")
        end

        # Display synthesis start message
        #
        # @param report_count [Integer] Number of reports
        # @param model [String] Model being used
        def display_synthesis_start(report_count, model)
          $stderr.puts
          $stderr.puts "Synthesizing feedback from #{report_count} review reports..."
          $stderr.puts "  Using model: #{model}"
          $stderr.flush
        end

        # Display synthesis completion message
        #
        # @param item_count [Integer] Number of items extracted
        # @param consensus_count [Integer] Number with consensus
        def display_synthesis_complete(item_count, consensus_count)
          $stderr.puts "✓ Synthesis complete"
          $stderr.puts "  Unique findings: #{item_count}"
          $stderr.puts "  Consensus items: #{consensus_count}" if consensus_count > 0
          $stderr.flush
        end

        # Create error result hash
        #
        # @param message [String] Error message
        # @param backtrace [Array<String>, nil] Optional backtrace
        # @return [Hash] Error result
        def error_result(message, backtrace: nil)
          result = { success: false, error: message }
          result[:backtrace] = backtrace if backtrace
          result
        end
      end
    end
  end
end
