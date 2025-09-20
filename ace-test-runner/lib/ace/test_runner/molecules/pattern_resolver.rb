# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      class PatternResolver
        def initialize(config)
          @config = config
          @patterns = config.patterns || {}
          @groups = config.groups || {}
        end

        def resolve_target(target)
          return resolve_all_files if target.nil? || target == "all"
          return [target] if File.exist?(target)

          if @groups.key?(target)
            resolve_group(target)
          elsif @patterns.key?(target)
            expand_pattern(@patterns[target])
          else
            raise ArgumentError, "Unknown target: #{target}. Available targets: #{available_targets.join(', ')}"
          end
        end

        def resolve_multiple_targets(targets)
          targets.flat_map { |target| resolve_target(target) }.uniq
        end

        def available_targets
          (@groups.keys + @patterns.keys).sort
        end

        def classify_file(file_path)
          @patterns.each do |name, pattern|
            return name if File.fnmatch?(pattern, file_path)
          end
          "other"
        end

        private

        def resolve_group(group_name)
          group_members = @groups[group_name]
          return [] unless group_members

          group_members.flat_map do |member|
            if @groups.key?(member)
              resolve_group(member) # Recursive expansion
            elsif @patterns.key?(member)
              expand_pattern(@patterns[member])
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
          if @groups.key?("all")
            resolve_group("all")
          else
            # Default: all Ruby test files
            expand_pattern("test/**/*_test.rb")
          end
        end
      end
    end
  end
end