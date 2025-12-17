# frozen_string_literal: true

require_relative "../molecules/gh_pr_executor"

module Ace
  module Context
    module Organisms
      # Loads PR diff content into context
      #
      # Responsible for:
      # - Normalizing PR references (string, array, hash formats)
      # - Fetching diffs via GhPrExecutor
      # - Integrating results into context sections
      # - Error handling and surfacing
      #
      # @example Basic usage
      #   loader = PrContextLoader.new(timeout: 60)
      #   loader.process(context, ["123", "owner/repo#456"])
      #
      class PrContextLoader
        # @param options [Hash] Configuration options
        # @option options [Integer] :timeout Timeout for gh commands (default: 30)
        # @option options [Boolean] :debug Enable debug output
        def initialize(options = {})
          @timeout = options[:timeout] || Molecules::GhPrExecutor::DEFAULT_TIMEOUT
          @debug = options[:debug] || false
        end

        # Process PR references and add diffs to context
        #
        # @param context [Models::ContextData] Context to populate
        # @param pr_refs [Array<String>, String, Hash, nil] PR reference(s)
        # @return [Boolean] true if at least one diff was successfully fetched
        def process(context, pr_refs)
          normalized = normalize_pr_refs(pr_refs)
          return false if normalized.empty?

          processed_diffs = fetch_all_diffs(context, normalized)
          successful_diffs = processed_diffs.select { |d| d[:success] }

          if successful_diffs.empty?
            surface_errors_to_content(context)
            return false
          end

          add_diffs_to_context(context, processed_diffs)
          true
        end

        private

        # Normalize PR refs to array, deduplicate, and remove empty/nil values
        # Handles both string refs and hash refs (for future extensibility)
        #
        # @param pr_refs [String, Array, Hash, nil] PR reference(s)
        # @return [Array<String>] Normalized, deduplicated PR refs
        def normalize_pr_refs(pr_refs)
          refs = pr_refs.is_a?(Array) ? pr_refs.flatten : [pr_refs]
          refs.map do |ref|
            case ref
            when String then ref.strip
            when Hash then ref[:number]&.to_s || ref["number"]&.to_s
            else ref&.to_s
            end
          end.compact.reject(&:empty?).uniq
        end

        # Fetch diffs for all PR refs, recording errors in context metadata
        #
        # @param context [Models::ContextData] Context for error recording
        # @param pr_refs [Array<String>] Normalized PR refs
        # @return [Array<Hash>] Processed diff results
        def fetch_all_diffs(context, pr_refs)
          pr_refs.map do |pr_ref|
            fetch_single_diff(context, pr_ref)
          end.compact
        end

        # Fetch diff for a single PR reference
        #
        # @param context [Models::ContextData] Context for error recording
        # @param pr_ref [String] Single PR reference
        # @return [Hash, nil] Diff result or nil on skip
        def fetch_single_diff(context, pr_ref)
          executor = Molecules::GhPrExecutor.new(pr_ref, timeout: @timeout)
          result = executor.fetch_diff

          if result[:success]
            {
              range: result[:source],
              output: result[:diff],
              success: true,
              source: :pr
            }
          else
            nil # Should not reach here; errors raise exceptions
          end
        rescue Molecules::GhPrExecutor::GhNotInstalledError,
               Molecules::GhPrExecutor::GhAuthenticationError,
               Molecules::GhPrExecutor::PrNotFoundError,
               Molecules::GhPrExecutor::GhCommandError,
               Molecules::GhPrExecutor::TimeoutError => e
          record_error(context, "PR fetch failed for '#{pr_ref}': #{e.message}")
          { range: "pr:#{pr_ref}", success: false, error: e.message, source: :pr }
        rescue ArgumentError => e
          record_error(context, "Invalid PR identifier '#{pr_ref}': #{e.message}")
          nil
        end

        # Record error in context metadata
        #
        # @param context [Models::ContextData] Context to update
        # @param message [String] Error message
        def record_error(context, message)
          context.metadata[:errors] ||= []
          context.metadata[:errors] << message
        end

        # Surface errors to content for callers who don't inspect metadata
        #
        # @param context [Models::ContextData] Context to update
        def surface_errors_to_content(context)
          return unless context.metadata[:errors]&.any?

          error_notice = context.metadata[:errors].map { |e| "- #{e}" }.join("\n")
          context.content = "**PR Fetch Errors:**\n#{error_notice}\n\n" + (context.content || "")
        end

        # Add processed diffs to context's diffs section
        #
        # @param context [Models::ContextData] Context to update
        # @param processed_diffs [Array<Hash>] Diff results to add
        def add_diffs_to_context(context, processed_diffs)
          context.sections ||= {}
          context.sections["diffs"] ||= { title: "Diffs", _processed_diffs: [] }
          context.sections["diffs"][:_processed_diffs] ||= []
          context.sections["diffs"][:_processed_diffs].concat(processed_diffs)
        end
      end
    end
  end
end
