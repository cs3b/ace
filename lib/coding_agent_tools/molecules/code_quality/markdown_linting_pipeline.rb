# frozen_string_literal: true

require_relative "../../atoms/code_quality/task_metadata_validator"
require_relative "../../atoms/code_quality/markdown_link_validator"
require_relative "../../atoms/code_quality/template_embedding_validator"
require_relative "../../atoms/code_quality/kramdown_formatter"

module CodingAgentTools
  module Molecules
    module CodeQuality
      # Molecule for coordinating Markdown linting operations
      class MarkdownLintingPipeline
        attr_reader :config, :path_resolver

        def initialize(config:, path_resolver:)
          @config = config
          @path_resolver = path_resolver
        end

        def run(paths: ["."], autofix: false)
          results = {
            success: true,
            linters: {},
            total_issues: 0
          }

          markdown_config = config["markdown"] || {}
          return results unless markdown_config["enabled"]

          linters = markdown_config["linters"] || {}
          order = markdown_config["order"] || linters.keys

          # Run linters in specified order
          order.each do |linter_name|
            next unless linters.dig(linter_name, "enabled")

            case linter_name
            when "task_metadata"
              run_task_metadata(paths, results)
            when "link_validation"
              run_link_validation(paths, results)
            when "template_embedding"
              run_template_embedding(paths, results)
            when "styleguide"
              run_styleguide(paths, autofix, results)
            end
          end

          results
        end

        private

        def run_task_metadata(paths, results)
          validator = Atoms::CodeQuality::TaskMetadataValidator.new
          result = validator.validate

          results[:linters][:task_metadata] = result
          results[:success] &&= result[:success]
          results[:total_issues] += (result[:errors] || []).size
        rescue StandardError => e
          results[:linters][:task_metadata] = {
            success: false,
            error: e.message
          }
          results[:success] = false
        end

        def run_link_validation(paths, results)
          validator = Atoms::CodeQuality::MarkdownLinkValidator.new(
            root: path_resolver.project_root
          )
          
          resolved_paths = paths.map { |p| path_resolver.resolve(p) }
          result = validator.validate(resolved_paths)

          results[:linters][:link_validation] = result
          results[:success] &&= result[:success]
          results[:total_issues] += result[:findings].size
        rescue StandardError => e
          results[:linters][:link_validation] = {
            success: false,
            error: e.message
          }
          results[:success] = false
        end

        def run_template_embedding(paths, results)
          validator = Atoms::CodeQuality::TemplateEmbeddingValidator.new
          
          resolved_paths = paths.map { |p| path_resolver.resolve(p) }
          result = validator.validate(resolved_paths)

          results[:linters][:template_embedding] = result
          results[:success] &&= result[:success]
          results[:total_issues] += result[:findings].size
        rescue StandardError => e
          results[:linters][:template_embedding] = {
            success: false,
            error: e.message
          }
          results[:success] = false
        end

        def run_styleguide(paths, autofix, results)
          formatter = Atoms::CodeQuality::KramdownFormatter.new(
            dry_run: !autofix
          )
          
          findings = []
          resolved_paths = paths.map { |p| path_resolver.resolve(p) }
          
          # Find all markdown files
          md_files = resolved_paths.flat_map do |path|
            if File.directory?(path)
              Dir.glob(File.join(path, "**", "*.md"))
            elsif path.end_with?(".md")
              [path]
            else
              []
            end
          end

          md_files.each do |file|
            result = formatter.format_file(file)
            if result[:changed]
              findings << {
                file: file,
                message: "Formatting changes needed",
                fixed: result[:file_updated]
              }
            end
          end

          results[:linters][:styleguide] = {
            success: true,
            findings: findings,
            total_files: md_files.size,
            files_changed: findings.size
          }
          
          results[:total_issues] += findings.size
        rescue StandardError => e
          results[:linters][:styleguide] = {
            success: false,
            error: e.message
          }
          results[:success] = false
        end
      end
    end
  end
end