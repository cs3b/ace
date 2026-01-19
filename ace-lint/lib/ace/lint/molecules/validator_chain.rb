# frozen_string_literal: true

require_relative "../atoms/validator_registry"
require_relative "../atoms/config_locator"
require_relative "offense_deduplicator"

module Ace
  module Lint
    module Molecules
      # Executes multiple validators sequentially and aggregates results
      # Handles validator availability, fallbacks, and result deduplication
      class ValidatorChain
        attr_reader :validators, :fallback_validators, :warnings

        # Initialize with validators to run
        # @param validators [Array<Symbol>] Primary validators to run
        # @param fallback_validators [Array<Symbol>] Fallback validators if primary unavailable
        # @param project_root [String, nil] Project root for config lookup
        def initialize(validators, fallback_validators: [], project_root: nil)
          @validators = Array(validators)
          @fallback_validators = Array(fallback_validators)
          @project_root = project_root || Dir.pwd
          @warnings = []
        end

        # Run validators on file(s)
        # @param file_paths [Array<String>] Paths to lint
        # @param fix [Boolean] Apply autofix
        # @return [Hash] Aggregated result with :success, :errors, :warnings, :runners
        def run(file_paths, fix: false)
          paths = Array(file_paths)
          return empty_result if paths.empty?

          # Determine which validators to actually run
          active_validators = resolve_validators

          if active_validators.empty?
            return unavailable_result
          end

          # Run each validator and collect results
          all_results = []
          runners_used = []

          active_validators.each do |validator_name|
            runner = Atoms::ValidatorRegistry.runner_for(validator_name)
            next unless runner

            # Look up config for this validator using ConfigLocator
            config = Atoms::ConfigLocator.locate(validator_name, project_root: @project_root)
            config_path = config[:exists] ? config[:path] : nil

            result = runner.run(paths, fix: fix, config_path: config_path)
            all_results << result
            runners_used << validator_name
          end

          # Aggregate and deduplicate results
          aggregate_results(all_results, runners_used)
        end

        private

        # Resolve which validators to run based on availability
        # @return [Array<Symbol>] Validators to run
        def resolve_validators
          active = []

          # Check primary validators
          @validators.each do |name|
            if Atoms::ValidatorRegistry.available?(name)
              active << name
            else
              @warnings << "Validator '#{name}' is not available, skipping"
            end
          end

          # If no primary validators available, try fallbacks
          if active.empty?
            @fallback_validators.each do |name|
              if Atoms::ValidatorRegistry.available?(name)
                active << name
                @warnings << "Using fallback validator '#{name}'"
              end
            end
          end

          active
        end

        # Aggregate results from multiple validators
        # @param results [Array<Hash>] Results from each validator
        # @param runners [Array<Symbol>] Validators that were run
        # @return [Hash] Aggregated result
        def aggregate_results(results, runners)
          return empty_result if results.empty?

          all_errors = []
          all_warnings = []

          results.each do |result|
            all_errors.concat(result[:errors] || [])
            all_warnings.concat(result[:warnings] || [])
          end

          # Deduplicate by line:column:message using OffenseDeduplicator
          deduped_errors = OffenseDeduplicator.deduplicate(all_errors)
          deduped_warnings = OffenseDeduplicator.deduplicate(all_warnings)

          # Success only if all validators succeeded
          success = results.all? { |r| r[:success] }

          {
            success: success,
            errors: deduped_errors,
            warnings: deduped_warnings,
            runners: runners,
            chain_warnings: @warnings
          }
        end

        # Empty result when no files to lint
        # @return [Hash] Empty success result
        def empty_result
          {
            success: true,
            errors: [],
            warnings: [],
            runners: [],
            chain_warnings: @warnings
          }
        end

        # Result when no validators are available
        # @return [Hash] Error result
        def unavailable_result
          {
            success: false,
            errors: [{
              message: "No validators available. Install StandardRB: gem install standardrb"
            }],
            warnings: [],
            runners: [],
            chain_warnings: @warnings
          }
        end
      end
    end
  end
end
