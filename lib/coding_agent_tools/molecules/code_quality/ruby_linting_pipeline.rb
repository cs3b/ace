# frozen_string_literal: true

require_relative '../../atoms/code_quality/standard_rb_validator'
require_relative '../../atoms/code_quality/security_validator'
require_relative '../../atoms/code_quality/cassettes_validator'

module CodingAgentTools
  module Molecules
    module CodeQuality
      # Molecule for coordinating Ruby linting operations
      class RubyLintingPipeline
        attr_reader :config, :path_resolver

        def initialize(config:, path_resolver:)
          @config = config
          @path_resolver = path_resolver
        end

        def run(paths: ['.'], autofix: false)
          results = {
            success: true,
            linters: {},
            total_issues: 0
          }

          ruby_config = config['ruby'] || {}
          return results unless ruby_config['enabled']

          linters = ruby_config['linters'] || {}

          # Run StandardRB
          run_standardrb(paths, autofix, results) if linters.dig('standardrb', 'enabled')

          # Run Security check
          run_security(paths, linters['security'], results) if linters.dig('security', 'enabled')

          # Run Cassettes check
          run_cassettes(linters['cassettes'], results) if linters.dig('cassettes', 'enabled')
          results
        end

        private

        def run_standardrb(paths, autofix, results)
          validator = Atoms::CodeQuality::StandardRbValidator.new

          resolved_paths = paths.map { |p| path_resolver.resolve(p) }
          autofix_enabled = config.dig('ruby', 'linters', 'standardrb', 'autofix')

          result = if autofix && autofix_enabled
            validator.autofix(resolved_paths)
          else
            validator.validate(resolved_paths)
          end

          results[:linters][:standardrb] = result
          results[:success] &&= result[:success]
          results[:total_issues] += result[:findings].size
        rescue => e
          results[:linters][:standardrb] = {
            success: false,
            error: e.message,
            findings: []
          }
          results[:success] = false
        end

        def run_security(_paths, security_config, results)
          options = {
            full_scan: security_config['full_scan'] || false,
            git_history: security_config['git_history'] || false
          }

          validator = Atoms::CodeQuality::SecurityValidator.new(options)
          result = validator.validate

          results[:linters][:security] = result
          results[:success] &&= result[:success]
          results[:total_issues] += result[:findings].size
        rescue => e
          results[:linters][:security] = {
            success: false,
            error: e.message,
            findings: []
          }
          results[:success] = false
        end

        def run_cassettes(cassettes_config, results)
          options = {
            threshold: cassettes_config['threshold'] || 51_200
          }

          validator = Atoms::CodeQuality::CassettesValidator.new(options)
          result = validator.validate

          results[:linters][:cassettes] = result
          # Cassettes validator only warns, doesn't fail
          results[:total_issues] += result[:findings].size
        rescue => e
          results[:linters][:cassettes] = {
            success: false,
            error: e.message,
            findings: []
          }
        end
      end
    end
  end
end
