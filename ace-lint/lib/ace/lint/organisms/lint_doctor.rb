# frozen_string_literal: true

require "date"
require "yaml"

require_relative "../atoms/validator_registry"
require_relative "../atoms/config_locator"
require_relative "../molecules/group_resolver"

module Ace
  module Lint
    module Organisms
      # Diagnostic tool for checking linting configuration health
      # Checks validator availability, config files, and pattern coverage
      class LintDoctor
        # Diagnostic result structure
        DiagnosticResult = Struct.new(:category, :level, :message, :details, keyword_init: true) do
          def error?
            level == :error
          end

          def warning?
            level == :warning
          end

          def info?
            level == :info
          end
        end

        attr_reader :project_root, :groups, :diagnostics

        # Initialize doctor with configuration
        # @param project_root [String] Project root directory
        # @param groups [Hash, nil] Ruby validator groups configuration
        def initialize(project_root: Dir.pwd, groups: nil)
          @project_root = project_root
          @groups = groups
          @diagnostics = []
        end

        # Run all diagnostic checks
        # @return [Array<DiagnosticResult>] All diagnostic results
        def diagnose
          @diagnostics = []

          check_validator_availability
          check_config_files
          check_pattern_coverage if @groups

          @diagnostics
        end

        # Check if all configured validators are available
        # @return [Array<DiagnosticResult>] Validator availability diagnostics
        def check_validator_availability
          results = []

          # Check registered validators
          Atoms::ValidatorRegistry.registered_validators.each do |name|
            results << if Atoms::ValidatorRegistry.available?(name)
              DiagnosticResult.new(
                category: :validator,
                level: :info,
                message: "#{name}: available",
                details: {validator: name, status: :available}
              )
            else
              DiagnosticResult.new(
                category: :validator,
                level: :warning,
                message: "#{name}: not installed",
                details: {validator: name, status: :unavailable}
              )
            end
          end

          # Check configured validators in groups
          if @groups
            configured_validators = collect_configured_validators
            configured_validators.each do |name|
              unless Atoms::ValidatorRegistry.available?(name)
                results << DiagnosticResult.new(
                  category: :validator,
                  level: :warning,
                  message: "Configured validator '#{name}' is not available",
                  details: {validator: name, status: :configured_unavailable}
                )
              end
            end
          end

          @diagnostics.concat(results)
          results
        end

        # Check if configured config files exist
        # @return [Array<DiagnosticResult>] Config file diagnostics
        def check_config_files
          results = []

          # Check for each validator's config
          Atoms::ValidatorRegistry.registered_validators.each do |name|
            config = Atoms::ConfigLocator.locate(name, project_root: @project_root)

            case config[:source]
            when :explicit
              if config[:exists]
                results << DiagnosticResult.new(
                  category: :config,
                  level: :info,
                  message: "#{name}: using explicit config at #{config[:path]}",
                  details: {validator: name, source: :explicit, path: config[:path]}
                )
                # Validate YAML syntax
                yaml_error = validate_yaml_syntax(config[:path], name)
                results << yaml_error if yaml_error
              else
                results << DiagnosticResult.new(
                  category: :config,
                  level: :error,
                  message: "#{name}: explicit config not found at #{config[:path]}",
                  details: {validator: name, source: :explicit, path: config[:path], exists: false}
                )
              end
            when :ace_config
              results << DiagnosticResult.new(
                category: :config,
                level: :info,
                message: "#{name}: using .ace/lint config at #{config[:path]}",
                details: {validator: name, source: :ace_config, path: config[:path]}
              )
              # Validate YAML syntax
              yaml_error = validate_yaml_syntax(config[:path], name)
              results << yaml_error if yaml_error
            when :native
              results << DiagnosticResult.new(
                category: :config,
                level: :info,
                message: "#{name}: using native config at #{config[:path]}",
                details: {validator: name, source: :native, path: config[:path]}
              )
              # Validate YAML syntax
              yaml_error = validate_yaml_syntax(config[:path], name)
              results << yaml_error if yaml_error
            when :gem_defaults
              results << DiagnosticResult.new(
                category: :config,
                level: :info,
                message: "#{name}: using gem default config",
                details: {validator: name, source: :gem_defaults, path: config[:path]}
              )
            when :none
              results << DiagnosticResult.new(
                category: :config,
                level: :info,
                message: "#{name}: using tool defaults (no config file)",
                details: {validator: name, source: :none}
              )
            end
          end

          @diagnostics.concat(results)
          results
        end

        # Check pattern coverage in groups configuration
        # @return [Array<DiagnosticResult>] Pattern coverage diagnostics
        def check_pattern_coverage
          return [] unless @groups

          results = []

          # Check for default group
          unless @groups.key?(:default) || @groups.key?("default")
            results << DiagnosticResult.new(
              category: :pattern,
              level: :warning,
              message: "No 'default' group defined - some files may not be matched",
              details: {issue: :no_default_group}
            )
          end

          # Check for overlapping patterns (info only)
          all_patterns = []
          @groups.each do |name, config|
            patterns = config[:patterns] || config["patterns"] || []
            patterns.each do |pattern|
              all_patterns << {group: name, pattern: pattern}
            end
          end

          # Info about configured groups
          @groups.each do |name, config|
            validators = config[:validators] || config["validators"] || []
            patterns = config[:patterns] || config["patterns"] || []

            results << DiagnosticResult.new(
              category: :pattern,
              level: :info,
              message: "Group '#{name}': #{validators.join(", ")} for #{patterns.size} pattern(s)",
              details: {group: name, validators: validators, pattern_count: patterns.size}
            )
          end

          @diagnostics.concat(results)
          results
        end

        # Check if there are any errors
        # @return [Boolean] True if any errors found
        def errors?
          @diagnostics.any?(&:error?)
        end

        # Check if there are any warnings
        # @return [Boolean] True if any warnings found
        def warnings?
          @diagnostics.any?(&:warning?)
        end

        # Get all errors
        # @return [Array<DiagnosticResult>] Error diagnostics
        def errors
          @diagnostics.select(&:error?)
        end

        # Get all warnings
        # @return [Array<DiagnosticResult>] Warning diagnostics
        def warnings
          @diagnostics.select(&:warning?)
        end

        private

        # Collect all validators referenced in groups configuration
        # @return [Array<Symbol>] All configured validator names
        def collect_configured_validators
          return [] unless @groups

          validators = Set.new

          @groups.each_value do |config|
            (config[:validators] || config["validators"] || []).each do |v|
              validators << v.to_sym
            end
            (config[:fallback_validators] || config["fallback_validators"] || []).each do |v|
              validators << v.to_sym
            end
          end

          validators.to_a
        end

        # Validate YAML syntax of a config file
        # @param path [String] Path to the config file
        # @param validator_name [Symbol, String] Name of the validator
        # @return [DiagnosticResult, nil] Error diagnostic if YAML is invalid, nil otherwise
        def validate_yaml_syntax(path, validator_name)
          return nil unless path && File.exist?(path)

          YAML.safe_load_file(path, permitted_classes: [Date, Symbol], aliases: true)
          nil
        rescue Psych::SyntaxError => e
          DiagnosticResult.new(
            category: :config,
            level: :error,
            message: "#{validator_name}: YAML syntax error in #{path}: #{e.message}",
            details: {validator: validator_name, path: path, error: e.message, line: e.line, column: e.column}
          )
        rescue Psych::BadAlias => e
          DiagnosticResult.new(
            category: :config,
            level: :error,
            message: "#{validator_name}: YAML alias error in #{path}: #{e.message}",
            details: {validator: validator_name, path: path, error: e.message}
          )
        rescue Errno::ENOENT, Errno::EACCES => e
          DiagnosticResult.new(
            category: :config,
            level: :warning,
            message: "#{validator_name}: Could not read #{path}: #{e.message}",
            details: {validator: validator_name, path: path, error: e.message}
          )
        end
      end
    end
  end
end
