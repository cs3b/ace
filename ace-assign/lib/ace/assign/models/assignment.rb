# frozen_string_literal: true

module Ace
  module Assign
    module Models
      # Assignment data model representing a workflow assignment.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # All attributes are immutable after initialization.
      #
      # @example
      #   assignment = Assignment.new(
      #     id: "8or5kx",
      #     name: "my-workflow",
      #     description: "Example workflow",
      #     created_at: Time.now,
      #     source_config: "job.yaml"
      #   )
      # NOTE: Could be refactored to use Data.define in Ruby 3.2+ for reduced boilerplate,
      # but tests would need to be updated to provide all required fields.
      class Assignment
        attr_reader :id, :name, :description, :created_at, :updated_at, :source_config, :cache_dir, :parent,
          :task_id, :project_id

        # @param id [String] Unique assignment ID (6-char compact timestamp)
        # @param name [String] Human-readable assignment name
        # @param description [String, nil] Optional assignment description
        # @param created_at [Time] When assignment was created
        # @param updated_at [Time, nil] When assignment was last updated
        # @param source_config [String] Path to source configuration file
        # @param cache_dir [String, nil] Assignment cache directory
        # @param parent [String, nil] Parent assignment ID for hierarchy linking
        # @param task_id [String, nil] Source task ID attached to this assignment (nil = taskless)
        # @param project_id [String, nil] Project ID this assignment executes in
        def initialize(id:, name:, created_at:, source_config:, description: nil, updated_at: nil, cache_dir: nil,
          parent: nil, task_id: nil, project_id: nil)
          @id = id.freeze
          @name = name.freeze
          @description = description&.freeze
          @created_at = created_at
          @updated_at = updated_at || created_at
          @source_config = source_config.freeze
          @cache_dir = cache_dir&.freeze
          @parent = parent&.freeze
          @task_id = task_id&.freeze
          @project_id = project_id&.freeze
        end

        # @return [Boolean] True when a source task is attached; taskless
        #   assignments persist attempts locally only and never claim
        #   Git-backed recovery
        def managed?
          !task_id.nil? && !task_id.to_s.strip.empty?
        end

        # Convert to hash for YAML serialization
        # @return [Hash] Assignment data as hash
        def to_h
          {
            "session_id" => id,
            "name" => name,
            "description" => description,
            "created_at" => created_at.iso8601,
            "updated_at" => updated_at.iso8601,
            "source_config" => source_config,
            "parent" => parent,
            "task_id" => task_id,
            "project_id" => project_id
          }.compact
        end

        # Create from hash (YAML deserialization)
        # @param data [Hash] Assignment data hash
        # @param cache_dir [String, nil] Assignment cache directory
        # @return [Assignment] Assignment instance
        def self.from_h(data, cache_dir: nil)
          new(
            id: data["session_id"],
            name: data["name"],
            description: data["description"],
            created_at: parse_time(data["created_at"]),
            updated_at: parse_time(data["updated_at"]),
            source_config: data["source_config"],
            cache_dir: cache_dir,
            parent: data["parent"],
            task_id: data["task_id"],
            project_id: data["project_id"]
          )
        end

        # @return [String] Path to steps directory
        def steps_dir
          return nil unless cache_dir

          File.join(cache_dir, "steps")
        end

        # @return [String] Path to reports directory
        def reports_dir
          return nil unless cache_dir

          File.join(cache_dir, "reports")
        end

        # @return [String] Path to assignment.yaml file
        def assignment_file
          return nil unless cache_dir

          File.join(cache_dir, "assignment.yaml")
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
