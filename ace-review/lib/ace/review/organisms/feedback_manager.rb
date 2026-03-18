# frozen_string_literal: true

require "fileutils"

module Ace
  module Review
    module Organisms
      # Central orchestrator for feedback item lifecycle management.
      #
      # Coordinates the extraction, storage, querying, and state transitions
      # of feedback items from code reviews. Works with atoms and molecules
      # to provide a unified interface for feedback management.
      #
      # With the feedback synthesis architecture, multiple review reports are
      # synthesized into unique, deduplicated feedback items with reviewer arrays
      # tracking which models found each issue.
      #
      # @example Extract and save feedback from review reports
      #   manager = FeedbackManager.new
      #   result = manager.extract_and_save(
      #     report_paths: ["review-report-gemini.md"],
      #     base_path: "/project"
      #   )
      #   result[:success] #=> true
      #   result[:items_count] #=> 5
      #
      # @example Multi-report synthesis (deduplicated with reviewer arrays)
      #   result = manager.extract_and_save(
      #     report_paths: [
      #       "review-report-gemini.md",
      #       "review-report-claude.md",
      #       "review-report-gpt.md"
      #     ],
      #     base_path: "/project"
      #   )
      #   # Produces ~11 unique findings (not 33 duplicates)
      #
      # @example Query feedback items
      #   items = manager.list("/project", status: "pending")
      #   item = manager.find("/project", "abc123")
      #   stats = manager.stats("/project")
      #
      # @example State transitions
      #   manager.verify("/project", "abc123", valid: true)
      #   manager.skip("/project", "abc123", reason: "Not applicable")
      #   manager.resolve("/project", "abc123", resolution: "Fixed in commit abc")
      #
      class FeedbackManager
        attr_reader :synthesizer, :file_writer, :file_reader, :directory_manager

        def initialize(
          synthesizer: nil,
          file_writer: nil,
          file_reader: nil,
          directory_manager: nil
        )
          @synthesizer = synthesizer || Molecules::FeedbackSynthesizer.new
          @file_writer = file_writer || Molecules::FeedbackFileWriter.new
          @file_reader = file_reader || Molecules::FeedbackFileReader.new
          @directory_manager = directory_manager || Molecules::FeedbackDirectoryManager.new
        end

        # ========================================================================
        # Extraction
        # ========================================================================

        # Extract and synthesize feedback items from review reports and save to disk
        #
        # For multiple reports, uses FeedbackSynthesizer to produce deduplicated
        # findings with reviewer arrays. For single reports, extracts directly.
        #
        # @param report_paths [Array<String>] Paths to review report files
        # @param base_path [String] Base project path for feedback directory
        # @param model [String, nil] Model for synthesis/extraction (optional)
        # @param session_dir [String, nil] Session directory for LLM output (optional)
        # @return [Hash] Result with :success, :items_count, :paths, :metadata or :error
        #
        # @example Single report
        #   result = manager.extract_and_save(
        #     report_paths: ["session/review-report-gemini.md"],
        #     base_path: "/project"
        #   )
        #   result #=> { success: true, items_count: 3, paths: [...] }
        #
        # @example Multi-report synthesis
        #   result = manager.extract_and_save(
        #     report_paths: [
        #       "session/review-report-gemini.md",
        #       "session/review-report-claude.md"
        #     ],
        #     base_path: "/project"
        #   )
        #   # Produces deduplicated findings with reviewers arrays
        def extract_and_save(report_paths:, base_path:, model: nil, session_dir: nil)
          # Step 1: Synthesize feedback items from reports (handles deduplication)
          synthesis_result = @synthesizer.synthesize(
            report_paths: report_paths,
            session_dir: session_dir,
            model: model
          )

          unless synthesis_result[:success]
            return { success: false, error: synthesis_result[:error] }
          end

          items = synthesis_result[:items]
          return { success: true, items_count: 0, paths: [], metadata: synthesis_result[:metadata] } if items.empty?

          # Step 2: Ensure feedback directory exists
          feedback_dir = @directory_manager.ensure_directory(base_path)

          # Step 3: Save each item
          saved_paths = []
          errors = []

          items.each do |item|
            write_result = @file_writer.write(item, feedback_dir)

            if write_result[:success]
              saved_paths << write_result[:path]
            else
              errors << "Failed to save #{item.id}: #{write_result[:error]}"
            end
          end

          if errors.any? && saved_paths.empty?
            return { success: false, error: errors.join("; ") }
          end

          {
            success: true,
            items_count: saved_paths.length,
            paths: saved_paths,
            metadata: synthesis_result[:metadata],
            warnings: errors.any? ? errors : nil
          }.compact
        end

        # ========================================================================
        # Querying
        # ========================================================================

        # List feedback items with optional filters
        #
        # @param base_path [String] Base project path
        # @param status [String, nil] Filter by status (draft, pending, invalid, skip, done)
        # @param priority [String, nil] Filter by priority (critical, high, medium, low)
        # @return [Array<Models::FeedbackItem>] Matching feedback items
        #
        # @example List all items
        #   items = manager.list("/project")
        #
        # @example Filter by status
        #   pending_items = manager.list("/project", status: "pending")
        #
        # @example Filter by status and priority
        #   high_pending = manager.list("/project", status: "pending", priority: "high")
        def list(base_path, status: nil, priority: nil)
          feedback_dir = @directory_manager.feedback_path(base_path)
          return [] unless Dir.exist?(feedback_dir)

          items = @file_reader.read_all(feedback_dir)

          # Apply status filter
          items = items.select { |item| item.status == status } if status

          # Apply priority filter (supports exact match "high" or range "high+")
          items = items.select { |item| Atoms::PriorityFilter.matches?(item.priority, priority) } if priority

          # Sort by ID (chronological since IDs are timestamp-based)
          items.sort_by(&:id)
        end

        # Find a specific feedback item by ID
        #
        # @param base_path [String] Base project path
        # @param id [String] Feedback item ID (10-char Base36)
        # @return [Models::FeedbackItem, nil] The found item or nil
        #
        # @example
        #   item = manager.find("/project", "abc123")
        #   item&.title #=> "Missing error handling"
        def find(base_path, id)
          feedback_dir = @directory_manager.feedback_path(base_path)
          return nil unless Dir.exist?(feedback_dir)

          # Find file matching ID pattern
          files = Dir.glob(File.join(feedback_dir, "#{id}-*.s.md"))
          return nil if files.empty?

          # Read and return the item
          result = @file_reader.read(files.first)
          result[:success] ? result[:feedback_item] : nil
        end

        # Get statistics about feedback items
        #
        # @param base_path [String] Base project path
        # @return [Hash] Statistics with status counts
        #
        # @example
        #   stats = manager.stats("/project")
        #   stats #=> { draft: 2, pending: 3, invalid: 1, skip: 0, done: 5, total: 11 }
        def stats(base_path)
          # Get items from active directory
          active_items = list(base_path)

          # Get archived items
          archive_dir = @directory_manager.archive_path(base_path)
          archived_items = []
          if Dir.exist?(archive_dir)
            archived_items = @file_reader.read_all(archive_dir)
          end

          all_items = active_items + archived_items

          # Count by status
          counts = Models::FeedbackItem::VALID_STATUSES.map do |status|
            [status.to_sym, all_items.count { |item| item.status == status }]
          end.to_h

          counts[:total] = all_items.length
          counts
        end

        # ========================================================================
        # State Transitions
        # ========================================================================

        # Verify a feedback item (draft -> pending, draft -> invalid, or draft/pending -> skip)
        #
        # @param base_path [String] Base project path
        # @param id [String] Feedback item ID
        # @param valid [Boolean, nil] Whether the feedback is valid (mutually exclusive with skip:)
        # @param skip [Boolean, nil] Whether to skip the feedback (mutually exclusive with valid:)
        # @param research [String, nil] Verification research notes (optional)
        # @return [Hash] Result with :success, :item or :error
        #
        # @example Mark as valid
        #   result = manager.verify("/project", "abc123", valid: true, research: "Confirmed issue")
        #
        # @example Mark as invalid
        #   result = manager.verify("/project", "abc123", valid: false, research: "False positive")
        #
        # @example Skip
        #   result = manager.verify("/project", "abc123", skip: true, research: "Design decision")
        def verify(base_path, id, valid: nil, skip: nil, research: nil)
          # Validate mutually exclusive options
          if valid.nil? && skip.nil?
            return { success: false, error: "Must specify either valid: or skip:" }
          end
          if !valid.nil? && !skip.nil?
            return { success: false, error: "Cannot specify both valid: and skip:" }
          end

          target_status = if skip
                            "skip"
                          elsif valid
                            "pending"
                          else
                            "invalid"
                          end

          allowed_from = if skip
                           %w[draft pending]
                         else
                           ["draft"]
                         end

          transition(
            base_path: base_path,
            id: id,
            to_status: target_status,
            allowed_from: allowed_from,
            updates: research ? { research: research } : {}
          )
        end

        # Skip a feedback item (draft/pending -> skip)
        #
        # @param base_path [String] Base project path
        # @param id [String] Feedback item ID
        # @param reason [String, nil] Reason for skipping (optional, aliased to research)
        # @return [Hash] Result with :success, :item or :error
        #
        # @example
        #   result = manager.skip("/project", "abc123", reason: "Out of scope for this PR")
        #
        # @note For new code, prefer verify(base_path, id, skip: true, research: reason)
        def skip(base_path, id, reason: nil)
          verify(base_path, id, skip: true, research: reason)
        end

        # Resolve a feedback item (pending -> done)
        #
        # @param base_path [String] Base project path
        # @param id [String] Feedback item ID
        # @param resolution [String] Description of how the issue was resolved
        # @return [Hash] Result with :success, :item or :error
        #
        # @example
        #   result = manager.resolve("/project", "abc123", resolution: "Added try-catch in commit abc")
        def resolve(base_path, id, resolution:)
          transition(
            base_path: base_path,
            id: id,
            to_status: "done",
            allowed_from: ["pending"],
            updates: { resolution: resolution }
          )
        end

        private

        # Perform a state transition on a feedback item
        #
        # @param base_path [String] Base project path
        # @param id [String] Feedback item ID
        # @param to_status [String] Target status
        # @param allowed_from [Array<String>] Allowed source statuses
        # @param updates [Hash] Additional attributes to update
        # @return [Hash] Result with :success, :item or :error
        def transition(base_path:, id:, to_status:, allowed_from:, updates: {})
          # Find the item
          item = find(base_path, id)
          return { success: false, error: "Feedback item not found: #{id}" } unless item

          # Validate transition
          unless Atoms::FeedbackStateValidator.valid_transition?(item.status, to_status)
            return {
              success: false,
              error: "Invalid transition from '#{item.status}' to '#{to_status}'. " \
                     "Allowed: #{Atoms::FeedbackStateValidator.allowed_transitions(item.status).join(', ')}"
            }
          end

          # Check if transition is from an allowed source status
          unless allowed_from.include?(item.status)
            return {
              success: false,
              error: "Cannot #{to_status} from '#{item.status}'. Must be: #{allowed_from.join(' or ')}"
            }
          end

          # Create updated item
          updated_item = item.dup_with(status: to_status, **updates)

          # Find the file path
          feedback_dir = @directory_manager.feedback_path(base_path)
          files = Dir.glob(File.join(feedback_dir, "#{id}-*.s.md"))
          return { success: false, error: "Feedback file not found: #{id}" } if files.empty?

          file_path = files.first

          # Write updated item
          write_result = @file_writer.write(updated_item, feedback_dir)
          unless write_result[:success]
            return { success: false, error: write_result[:error] }
          end

          # Archive if terminal state
          if Atoms::FeedbackStateValidator.should_archive?(to_status)
            archive_result = @directory_manager.archive(write_result[:path])
            unless archive_result[:success]
              # Log warning but don't fail the transition
              warn "Warning: Failed to archive #{id}: #{archive_result[:error]}" if Ace::Review.debug?
            end
          end

          # Remove old file if filename changed (due to slug or other reasons)
          # This must happen after archiving to preserve the file for archival
          if File.exist?(file_path) && file_path != write_result[:path]
            begin
              FileUtils.rm(file_path)
            rescue StandardError => e
              # Log warning but don't fail - file will remain in active directory
              warn "Warning: Failed to remove old file #{file_path}: #{e.message}" if Ace::Review.debug?
            end
          end

          { success: true, item: updated_item }
        end
      end
    end
  end
end
