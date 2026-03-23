# frozen_string_literal: true

require "ace/git"

module Ace
  module Bundle
    module Organisms
      # Loads PR diff content into bundle
      #
      # Responsible for:
      # - Normalizing PR references (string, array, hash formats)
      # - Fetching diffs via Ace::Git::Molecules::PrMetadataFetcher
      # - Integrating results into bundle sections
      # - Error handling and surfacing
      #
      # @example Basic usage
      #   loader = PrBundleLoader.new(timeout: 60)
      #   loader.process(bundle, ["123", "owner/repo#456"])
      #
      class PrBundleLoader
        # @param options [Hash] Configuration options
        # @option options [Integer] :timeout Timeout for gh commands (default from ace-git config)
        # @option options [Boolean] :debug Enable debug output
        def initialize(options = {})
          @timeout = options[:timeout] || Ace::Git.network_timeout
          @debug = options[:debug] || false
        end

        # Process PR references and add diffs to bundle
        #
        # @param bundle [Models::BundleData] Bundle to populate
        # @param pr_refs [Array<String>, String, Hash, nil] PR reference(s)
        # @return [Boolean] true if at least one diff was successfully fetched
        def process(bundle, pr_refs)
          normalized = normalize_pr_refs(pr_refs)
          return false if normalized.empty?

          processed_diffs = fetch_all_diffs(bundle, normalized)
          successful_diffs = processed_diffs.select { |d| d[:success] }

          if successful_diffs.empty?
            surface_errors_to_content(bundle)
            return false
          end

          add_diffs_to_bundle(bundle, processed_diffs)
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

        # Fetch diffs for all PR refs, recording errors in bundle metadata
        #
        # @param bundle [Models::BundleData] Bundle for error recording
        # @param pr_refs [Array<String>] Normalized PR refs
        # @return [Array<Hash>] Processed diff results
        def fetch_all_diffs(bundle, pr_refs)
          pr_refs.map do |pr_ref|
            fetch_single_diff(bundle, pr_ref)
          end.compact
        end

        # Fetch diff for a single PR reference
        #
        # @param bundle [Models::BundleData] Bundle for error recording
        # @param pr_ref [String] Single PR reference
        # @return [Hash, nil] Diff result or nil on skip
        def fetch_single_diff(bundle, pr_ref)
          result = Ace::Git::Molecules::PrMetadataFetcher.fetch_diff(pr_ref, timeout: @timeout)

          if result[:success]
            {
              range: result[:source],
              output: result[:diff],
              success: true,
              source: :pr
            }
          else
            record_error(bundle, "PR fetch failed for '#{pr_ref}': #{result[:error]}")
            {range: pr_range_identifier(pr_ref), output: "Error: #{result[:error]}", success: false, error: result[:error], source: :pr}
          end
        rescue Ace::Git::Error => e
          # Catches all ace-git errors: GitError, GhNotInstalledError, GhAuthenticationError,
          # PrNotFoundError, TimeoutError (all inherit from Ace::Git::Error)
          record_error(bundle, "PR fetch failed for '#{pr_ref}': #{e.message}")
          {range: pr_range_identifier(pr_ref), output: "Error: #{e.message}", success: false, error: e.message, source: :pr}
        rescue ArgumentError => e
          record_error(bundle, "Invalid PR identifier '#{pr_ref}': #{e.message}")
          nil
        end

        # Record error in bundle metadata
        #
        # @param bundle [Models::BundleData] Bundle to update
        # @param message [String] Error message
        def record_error(bundle, message)
          bundle.metadata[:errors] ||= []
          bundle.metadata[:errors] << message
        end

        # Generate standardized PR range identifier for error responses
        # @param pr_ref [String] PR reference
        # @return [String] Range identifier in "pr:ref" format
        def pr_range_identifier(pr_ref)
          "pr:#{pr_ref}"
        end

        # Surface errors to content for callers who don't inspect metadata
        #
        # @param bundle [Models::BundleData] Bundle to update
        def surface_errors_to_content(bundle)
          return unless bundle.metadata[:errors]&.any?

          error_notice = bundle.metadata[:errors].map { |e| "- #{e}" }.join("\n")
          bundle.content = "**PR Fetch Errors:**\n#{error_notice}\n\n" + (bundle.content || "")
        end

        # Add processed diffs to bundle's diffs section
        #
        # @param bundle [Models::BundleData] Bundle to update
        # @param processed_diffs [Array<Hash>] Diff results to add
        def add_diffs_to_bundle(bundle, processed_diffs)
          bundle.sections ||= {}
          bundle.sections["diffs"] ||= {title: "Diffs", _processed_diffs: []}
          bundle.sections["diffs"][:_processed_diffs] ||= []
          bundle.sections["diffs"][:_processed_diffs].concat(processed_diffs)
        end
      end
    end
  end
end
