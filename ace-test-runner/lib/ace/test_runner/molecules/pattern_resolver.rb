# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      class PatternResolver
        attr_reader :using_catch_all

        def initialize(config)
          @config = config
          @patterns = normalize_keys(config.patterns || {})
          @groups = normalize_keys(config.groups || {})
          @using_catch_all = false
        end

        def resolve_target(target)
          return resolve_all_files if target.nil? || target == "all"
          return [target] if File.exist?(target)

          # Normalize target to string for consistent lookup
          target_key = target.to_s

          if @groups.key?(target_key)
            resolve_group(target_key)
          elsif @patterns.key?(target_key)
            expand_pattern(@patterns[target_key])
          elsif looks_like_file_path?(target)
            raise ArgumentError, "File not found: #{target}. " \
              "Make sure you're running from the correct directory or use an absolute path."
          else
            raise ArgumentError, "Unknown target: #{target}. Available targets: #{available_targets.join(", ")}"
          end
        end

        def resolve_multiple_targets(targets)
          targets.flat_map { |target| resolve_target(target) }.uniq
        end

        def resolve_group_sequential(group_name)
          group_key = group_name.to_s
          group_members = @groups[group_key]
          return [] unless group_members

          group_members.flat_map do |member|
            member_key = member.to_s

            if @groups.key?(member_key)
              # Recursively expand nested groups
              resolve_group_sequential(member_key)
            elsif @patterns.key?(member_key)
              # Pattern found - return as a group
              files = expand_pattern(@patterns[member_key])
              files.empty? ? [] : [{name: member_key, files: files}]
            else
              # Direct pattern - expand and wrap
              files = expand_pattern(member)
              files.empty? ? [] : [{name: "other", files: files}]
            end
          end
        end

        def available_targets
          (@groups.keys + @patterns.keys).map(&:to_s).sort
        end

        def classify_file(file_path)
          @patterns.each do |name, pattern|
            # Use File::FNM_PATHNAME to handle ** correctly
            return name.to_s if File.fnmatch?(pattern, file_path, File::FNM_PATHNAME)
          end
          "other"
        end

        private

        def looks_like_file_path?(target)
          target.include?("/") || target.end_with?(".rb")
        end

        def normalize_keys(hash)
          hash.transform_keys(&:to_s)
        end

        def resolve_group(group_name)
          # Normalize to string
          group_key = group_name.to_s
          group_members = @groups[group_key]
          return [] unless group_members

          group_members.flat_map do |member|
            member_key = member.to_s

            if @groups.key?(member_key)
              resolve_group(member_key) # Recursive expansion
            elsif @patterns.key?(member_key)
              expand_pattern(@patterns[member_key])
            else
              # Direct pattern or file
              expand_pattern(member)
            end
          end.uniq
        end

        def expand_pattern(pattern)
          Dir.glob(pattern).select { |f| File.file?(f) }
        end

        def resolve_all_files
          # Catch-all default selection should not silently widen back into
          # deterministic E2E tests when the configured "all" target excludes them.
          all_test_files = expand_pattern("test/**/*_test.rb")
          catch_all_files = all_test_files - expand_pattern("test/e2e/**/*_test.rb")
          @using_catch_all = false

          # First check if "all" group is defined
          if @groups.key?("all")
            return resolve_group("all")
          end

          # If no "all" group, try all defined patterns
          if @patterns && !@patterns.empty?
            pattern_files = []
            @patterns.each_value do |pattern|
              pattern_files.concat(expand_pattern(pattern))
            end
            pattern_files = pattern_files.uniq
            # If patterns miss any files, use the complete scan
            if pattern_files.size < all_test_files.size
              @using_catch_all = true
              return catch_all_files
            end
            return pattern_files
          end

          # No configuration - using catch-all pattern
          @using_catch_all = true
          catch_all_files
        end
      end
    end
  end
end
