# frozen_string_literal: true

require_relative "../atoms/pattern_matcher"

module Ace
  module Lint
    module Molecules
      # Resolves which validator group applies to files based on pattern matching
      # Uses configuration groups with glob patterns to determine validators
      class GroupResolver
        # Default group configuration when no groups are defined
        DEFAULT_GROUPS = {
          default: {
            patterns: ["**/*.rb"],
            validators: [:standardrb],
            fallback_validators: [:rubocop]
          }
        }.freeze

        attr_reader :groups

        # Initialize with groups configuration
        # @param groups [Hash] Groups configuration from ruby.yml
        def initialize(groups = nil)
          @groups = normalize_groups(groups || DEFAULT_GROUPS)
        end

        # Resolve validator group for a single file
        # @param file_path [String] File path to resolve
        # @return [Hash] { group_name:, validators:, fallback_validators:, config: }
        def resolve(file_path)
          match = Atoms::PatternMatcher.best_group_match(file_path, @groups)

          if match
            group_name, config = match
            build_result(group_name, config)
          else
            # No match - use default group if available, otherwise return nil
            default = @groups[:default]
            if default
              build_result(:default, default)
            end
          end
        end

        # Resolve validator groups for multiple files, grouping them by matched group
        # @param file_paths [Array<String>] File paths to resolve
        # @return [Hash<Symbol, Hash>] Map of group_name => { files:, validators:, ... }
        def resolve_batch(file_paths)
          result = Hash.new { |h, k| h[k] = {files: []} }

          file_paths.each do |file_path|
            resolution = resolve(file_path)

            if resolution
              group_name = resolution[:group_name]
              result[group_name][:files] << file_path
              # Store group config (only once per group)
              result[group_name].merge!(resolution) { |_k, old, _new| old }
            else
              # Unmatched files go to :_unmatched_ group
              result[:_unmatched_][:files] << file_path
              result[:_unmatched_][:validators] ||= []
              result[:_unmatched_][:group_name] ||= :_unmatched_
            end
          end

          result
        end

        private

        # Normalize groups configuration to use symbols and arrays
        # @param groups [Hash] Raw groups configuration
        # @return [Hash] Normalized groups
        def normalize_groups(groups)
          return {} if groups.nil?

          groups.each_with_object({}) do |(name, config), result|
            result[name.to_sym] = {
              patterns: normalize_array(config[:patterns] || config["patterns"]),
              validators: normalize_validators(config[:validators] || config["validators"]),
              fallback_validators: normalize_validators(config[:fallback_validators] || config["fallback_validators"]),
              config_path: config[:config_path] || config["config_path"]
            }
          end
        end

        # Normalize array values
        # @param value [Array, String, nil] Value to normalize
        # @return [Array] Normalized array
        def normalize_array(value)
          return [] if value.nil?

          Array(value)
        end

        # Normalize validators to symbols
        # @param validators [Array, String, Symbol, nil] Validators to normalize
        # @return [Array<Symbol>] Normalized validators
        def normalize_validators(validators)
          return [] if validators.nil?

          Array(validators).map { |v| v.to_s.downcase.to_sym }
        end

        # Build result hash for a matched group
        # @param group_name [Symbol] Group name
        # @param config [Hash] Group configuration
        # @return [Hash] Resolution result
        def build_result(group_name, config)
          {
            group_name: group_name,
            validators: config[:validators] || [],
            fallback_validators: config[:fallback_validators] || [],
            config_path: config[:config_path]
          }
        end
      end
    end
  end
end
