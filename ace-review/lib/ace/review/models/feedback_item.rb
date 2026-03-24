# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Models
      # Represents a single feedback item from a code review.
      #
      # FeedbackItem is an immutable data structure containing all information
      # about a review finding, including its status, priority, and resolution.
      #
      # @example Creating a feedback item (multiple reviewers with consensus)
      #   item = FeedbackItem.new(
      #     id: "8o7abcd123",
      #     title: "Missing error handling",
      #     files: ["src/handlers/user.rb:42-55"],
      #     reviewers: ["google:gemini-2.5-flash", "anthropic:claude-3.5-sonnet", "openai:gpt-4"],
      #     status: "pending",
      #     priority: "high",
      #     consensus: true,
      #     finding: "The error handling is incomplete..."
      #   )
      #
      # @example Creating a modified copy
      #   resolved_item = item.dup_with(status: "done", resolution: "Added try-catch block")
      #
      class FeedbackItem
        # Valid status values for feedback items
        VALID_STATUSES = %w[draft pending invalid skip done].freeze

        # Valid priority values for feedback items
        VALID_PRIORITIES = %w[critical high medium low].freeze

        # Minimum number of reviewers for consensus
        CONSENSUS_THRESHOLD = 3

        attr_reader :id, :title, :files, :reviewers, :status, :priority,
          :created, :updated, :finding, :context, :research, :resolution, :consensus

        # Initialize a new FeedbackItem from a hash of attributes
        #
        # @param attrs [Hash] Attributes for the feedback item
        # @option attrs [String] :id 10-character Base36 ID (6-char timestamp + 4-char random)
        # @option attrs [String] :title Short description of the finding
        # @option attrs [Array<String>] :files File references (path:line-range format)
        # @option attrs [Array<String>] :reviewers LLM models that found this
        # @option attrs [String] :reviewer Single reviewer string (converted to reviewers array)
        # @option attrs [String] :status One of: draft, pending, invalid, skip, done
        # @option attrs [String] :priority One of: critical, high, medium, low
        # @option attrs [Boolean] :consensus True if 3+ models agree on this finding
        # @option attrs [String] :created ISO8601 timestamp
        # @option attrs [String] :updated ISO8601 timestamp
        # @option attrs [String] :finding Original finding text
        # @option attrs [String, nil] :context Additional context (optional)
        # @option attrs [String, nil] :research Verification research (optional)
        # @option attrs [String, nil] :resolution How it was resolved (optional)
        # @raise [ArgumentError] If status or priority values are invalid
        def initialize(attrs = {})
          # Support both symbol and string keys
          attrs = symbolize_keys(attrs)

          @id = attrs[:id]
          @title = attrs[:title]
          @files = Array(attrs[:files])

          @reviewers = normalize_reviewers(attrs[:reviewers], attrs[:reviewer])

          @status = attrs[:status] || "draft"
          @priority = attrs[:priority] || "medium"
          @created = attrs[:created] || Time.now.utc.iso8601
          @updated = attrs[:updated] || @created
          @finding = attrs[:finding]
          @context = attrs[:context]
          @research = attrs[:research]
          @resolution = attrs[:resolution]

          # Consensus: true if 3+ models agree (can be explicitly set or computed)
          @consensus = attrs.key?(:consensus) ? attrs[:consensus] : (@reviewers.length >= CONSENSUS_THRESHOLD)

          validate!
          freeze_arrays
        end

        # Accessor for single reviewer (returns first reviewer)
        # @return [String, nil] First reviewer or nil if none
        def reviewer
          @reviewers.first
        end

        # Convert the feedback item to a hash
        #
        # @return [Hash] Hash representation with string keys
        def to_h
          hash = {
            "id" => id,
            "title" => title,
            "files" => files.dup,
            "status" => status,
            "priority" => priority,
            "created" => created,
            "updated" => updated,
            "finding" => finding,
            "context" => context,
            "research" => research,
            "resolution" => resolution
          }

          # Use reviewers array if multiple reviewers, otherwise use singular reviewer key
          if @reviewers.length > 1
            hash["reviewers"] = @reviewers.dup
            hash["consensus"] = consensus if consensus
          else
            hash["reviewer"] = reviewer
          end

          hash.compact
        end

        # Convert the feedback item to YAML
        #
        # @return [String] YAML representation
        def to_yaml
          to_h.to_yaml
        end

        # Create a new FeedbackItem with modified attributes
        #
        # @param changes [Hash] Attributes to change
        # @return [FeedbackItem] New instance with merged attributes
        def dup_with(**changes)
          # Auto-update the updated timestamp when making changes
          changes[:updated] ||= Time.now.utc.iso8601
          FeedbackItem.new(to_h.merge(stringify_keys(changes)))
        end

        # Check if two feedback items are equal
        #
        # @param other [FeedbackItem] Other item to compare
        # @return [Boolean] True if equal
        def ==(other)
          return false unless other.is_a?(FeedbackItem)

          id == other.id &&
            title == other.title &&
            files == other.files &&
            reviewers == other.reviewers &&
            status == other.status &&
            priority == other.priority &&
            finding == other.finding
        end

        alias_method :eql?, :==

        # Hash code for use in hash tables
        #
        # @return [Integer] Hash code
        def hash
          [id, title, files, reviewers, status, priority, finding].hash
        end

        private

        # Validate status and priority values
        #
        # @raise [ArgumentError] If values are invalid
        def validate!
          unless VALID_STATUSES.include?(status)
            raise ArgumentError, "Invalid status '#{status}'. Must be one of: #{VALID_STATUSES.join(", ")}"
          end

          unless VALID_PRIORITIES.include?(priority)
            raise ArgumentError, "Invalid priority '#{priority}'. Must be one of: #{VALID_PRIORITIES.join(", ")}"
          end
        end

        # Freeze array attributes to ensure immutability
        def freeze_arrays
          @files.freeze
          @reviewers.freeze
        end

        # Normalize reviewers from various input formats
        #
        # @param reviewers [Array<String>, nil] Reviewers array
        # @param reviewer [String, nil] Single reviewer string
        # @return [Array<String>] Normalized reviewers array
        def normalize_reviewers(reviewers, reviewer)
          if reviewers.is_a?(Array) && reviewers.any?
            reviewers.map(&:to_s).reject(&:empty?)
          elsif reviewer && !reviewer.to_s.empty?
            [reviewer.to_s]
          else
            []
          end
        end

        # Convert hash keys to symbols
        #
        # @param hash [Hash] Hash with string or symbol keys
        # @return [Hash] Hash with symbol keys
        def symbolize_keys(hash)
          hash.transform_keys(&:to_sym)
        end

        # Convert hash keys to strings
        #
        # @param hash [Hash] Hash with string or symbol keys
        # @return [Hash] Hash with string keys
        def stringify_keys(hash)
          hash.transform_keys(&:to_s)
        end
      end
    end
  end
end
