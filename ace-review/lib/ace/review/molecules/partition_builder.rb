# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Splits a list of changed files into independent review partitions
      # based on glob-based partition definitions loaded from YAML files.
      #
      # Partition definitions live at review/partitions/<name>.yml in the config cascade.
      # Each definition contains named groups with glob patterns and an optional catch_all flag.
      #
      # When no strategy is specified (nil), returns a single partition wrapping all files,
      # preserving backward compatibility.
      #
      # @example Partitioning by concern
      #   files = ["lib/foo.rb", "handbook/guide.md"]
      #   partitions = PartitionBuilder.build(subject_files: files, strategy: "by-concern")
      #   # => [Partition(id: "partition-code", ...), Partition(id: "partition-handbook", ...)]
      #
      class PartitionBuilder
        FLAGS = File::FNM_PATHNAME | File::FNM_DOTMATCH

        # Build partitions from a list of files using the given strategy.
        #
        # @param subject_files [Array<String>] changed file paths
        # @param strategy [String, nil] partition definition name or nil
        # @param project_root [String, nil] project root for config lookup
        # @return [Array<Models::Partition>] one or more partitions
        def self.build(subject_files:, strategy:, project_root: nil)
          files = Array(subject_files).compact.reject(&:empty?)
          return [single_partition(files)] if strategy.nil? || strategy.to_s.strip.empty?
          return [] if files.empty?

          definition = load_definition(strategy.to_s.strip, project_root)
          raise ArgumentError, "Unknown partition '#{strategy}'" unless definition

          groups = definition["groups"] || {}
          catch_all = definition["catch_all"] == true

          build_from_globs(files, groups, strategy.to_s.strip, catch_all)
        end

        private_class_method def self.build_from_globs(files, groups, strategy, catch_all)
          matched = Set.new
          partitions = []

          groups.each do |group_name, globs|
            group_files = files.select do |f|
              next false if matched.include?(f)

              Array(globs).any? { |g| file_matches_glob?(f, g) }
            end
            group_files.each { |f| matched.add(f) }
            next if group_files.empty?

            partitions << Models::Partition.new(
              id: "partition-#{group_name}",
              label: group_name,
              files: group_files.sort,
              strategy: strategy,
              metadata: { "group" => group_name }
            )
          end

          if catch_all
            remaining = files.reject { |f| matched.include?(f) }
            unless remaining.empty?
              partitions << Models::Partition.new(
                id: "partition-other",
                label: "other",
                files: remaining.sort,
                strategy: strategy,
                metadata: { "group" => "other", "catch_all" => true }
              )
            end
          end

          partitions
        end

        # Match a file against a glob pattern, trying both the full path and
        # the path with the first directory component stripped (for mono-repo layouts
        # where glob patterns are relative to package root).
        private_class_method def self.file_matches_glob?(file, glob)
          return true if File.fnmatch?(glob, file, FLAGS)

          stripped = file.sub(%r{\A[^/]+/}, "")
          stripped != file && File.fnmatch?(glob, stripped, FLAGS)
        end

        private_class_method def self.single_partition(files)
          Models::Partition.new(
            id: "partition-all",
            label: "all files",
            files: files,
            strategy: "none",
            metadata: {}
          )
        end

        private_class_method def self.load_definition(name, project_root)
          validation = Atoms::PresetValidator.validate_preset_name(name)
          raise ArgumentError, validation[:error] unless validation[:success]

          finder = Ace::Support::Config.finder
          definition_file = finder.find_file("review/partitions/#{name}.yml")

          unless definition_file && File.exist?(definition_file)
            root = project_root || find_project_root
            fallback = File.join(root, ".ace/review/partitions/#{name}.yml")
            definition_file = fallback if File.exist?(fallback)
          end

          return nil unless definition_file && File.exist?(definition_file)

          raw = YAML.safe_load(File.read(definition_file), permitted_classes: [Symbol]) || {}
          deep_stringify_keys(raw)
        rescue ArgumentError
          raise
        rescue StandardError
          nil
        end

        private_class_method def self.deep_stringify_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
          when Array
            obj.map { |item| deep_stringify_keys(item) }
          else
            obj
          end
        end

        private_class_method def self.find_project_root
          Ace::Support::Config.find_project_root || Dir.pwd
        rescue StandardError
          Dir.pwd
        end
      end
    end
  end
end
