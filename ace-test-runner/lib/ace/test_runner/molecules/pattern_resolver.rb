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

          # Convert to symbol to match hash keys
          target_sym = target.to_sym if target.is_a?(String)

          if @groups.key?(target_sym) || @groups.key?(target)
            resolve_group(target_sym || target)
          elsif @patterns.key?(target_sym) || @patterns.key?(target)
            expand_pattern(@patterns[target_sym] || @patterns[target])
          else
            raise ArgumentError, "Unknown target: #{target}. Available targets: #{available_targets.join(', ')}"
          end
        end

        def resolve_multiple_targets(targets)
          targets.flat_map { |target| resolve_target(target) }.uniq
        end

        def available_targets
          (@groups.keys + @patterns.keys).map(&:to_s).sort
        end

        def classify_file(file_path)
          @patterns.each do |name, pattern|
            return name.to_s if File.fnmatch?(pattern, file_path)
          end
          "other"
        end

        private

        def resolve_group(group_name)
          # Handle both symbol and string keys
          group_name_sym = group_name.is_a?(String) ? group_name.to_sym : group_name
          group_members = @groups[group_name_sym] || @groups[group_name]
          return [] unless group_members

          group_members.flat_map do |member|
            # Convert member to symbol for lookups
            member_sym = member.is_a?(String) ? member.to_sym : member

            if @groups.key?(member_sym) || @groups.key?(member)
              resolve_group(member_sym || member) # Recursive expansion
            elsif @patterns.key?(member_sym) || @patterns.key?(member)
              expand_pattern(@patterns[member_sym] || @patterns[member])
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