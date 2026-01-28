# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Session data model representing a workflow session.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # All attributes are immutable after initialization.
      #
      # @example
      #   session = Session.new(
      #     id: "8or5kx",
      #     name: "my-workflow",
      #     description: "Example workflow",
      #     created_at: Time.now,
      #     source_config: "job.yaml"
      #   )
      class Session
        attr_reader :id, :name, :description, :created_at, :updated_at, :source_config, :cache_dir

        # @param id [String] Unique session ID (6-char compact timestamp)
        # @param name [String] Human-readable session name
        # @param description [String, nil] Optional session description
        # @param created_at [Time] When session was created
        # @param updated_at [Time, nil] When session was last updated
        # @param source_config [String] Path to source configuration file
        # @param cache_dir [String, nil] Session cache directory
        def initialize(id:, name:, description: nil, created_at:, updated_at: nil, source_config:, cache_dir: nil)
          @id = id.freeze
          @name = name.freeze
          @description = description&.freeze
          @created_at = created_at
          @updated_at = updated_at || created_at
          @source_config = source_config.freeze
          @cache_dir = cache_dir&.freeze
        end

        # Convert to hash for YAML serialization
        # @return [Hash] Session data as hash
        def to_h
          {
            "session_id" => id,
            "name" => name,
            "description" => description,
            "created_at" => created_at.iso8601,
            "updated_at" => updated_at.iso8601,
            "source_config" => source_config
          }.compact
        end

        # Create from hash (YAML deserialization)
        # @param data [Hash] Session data hash
        # @param cache_dir [String, nil] Session cache directory
        # @return [Session] Session instance
        def self.from_h(data, cache_dir: nil)
          new(
            id: data["session_id"],
            name: data["name"],
            description: data["description"],
            created_at: parse_time(data["created_at"]),
            updated_at: parse_time(data["updated_at"]),
            source_config: data["source_config"],
            cache_dir: cache_dir
          )
        end

        # @return [String] Path to jobs directory
        def jobs_dir
          return nil unless cache_dir

          File.join(cache_dir, "jobs")
        end

        # @return [String] Path to session.yaml file
        def session_file
          return nil unless cache_dir

          File.join(cache_dir, "session.yaml")
        end

        private

        def self.parse_time(value)
          return nil if value.nil?
          return value if value.is_a?(Time)

          Time.parse(value)
        end
        private_class_method :parse_time
      end
    end
  end
end
