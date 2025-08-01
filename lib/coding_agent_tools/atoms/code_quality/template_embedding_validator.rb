# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for validating template embedding in markdown documents
      # Validates that embedded templates follow proper format and exist
      class TemplateEmbeddingValidator
        # Common template embedding patterns
        TEMPLATE_PATTERNS = [
          /{{#include\s+(.+?)}}/,           # Mdbook style
          /<!--\s*#include\s+(.+?)\s*-->/,  # HTML comment style
          /{%\s*include\s+["'](.+?)["']\s*%}/, # Liquid style
          /\[\[include:(.+?)\]\]/ # Wiki style
        ].freeze

        attr_reader :template_dirs

        def initialize(options = {})
          @template_dirs = options[:template_dirs] || default_template_dirs
        end

        def validate(paths = ['.'])
          md_files = collect_markdown_files(paths)
          findings = []

          md_files.each do |file|
            validate_file_templates(file, findings)
          end

          {
            success: findings.empty?,
            findings: findings,
            errors: findings.map { |f| format_error(f) }
          }
        end

        private

        def default_template_dirs
          [
            'dev-handbook/.meta/tpl',
            'templates',
            '_includes'
          ]
        end

        def collect_markdown_files(paths)
          paths.flat_map do |p|
            if File.directory?(p)
              Dir.glob(File.join(p, '**', '*.md'))
            elsif File.exist?(p) && p.end_with?('.md')
              [p]
            else
              []
            end
          end
        end

        def validate_file_templates(file, findings)
          content = File.read(file)
          in_code_block = false

          content.each_line.with_index do |line, idx|
            # Skip code blocks
            if line.strip.start_with?('```', '~~~')
              in_code_block = !in_code_block
              next
            end

            next if in_code_block

            # Check each pattern
            TEMPLATE_PATTERNS.each do |pattern|
              line.scan(pattern) do |match|
                template_path = match.first

                unless template_exists?(template_path)
                  findings << {
                    file: file,
                    line: idx + 1,
                    template: template_path,
                    pattern: pattern.source
                  }
                end
              end
            end
          end
        end

        def template_exists?(template_path)
          # Check in each template directory
          template_dirs.any? do |dir|
            full_path = File.join(dir, template_path)
            File.exist?(full_path) || File.exist?("#{full_path}.md")
          end ||
            # Also check if it's an absolute path or relative to current dir
            File.exist?(template_path)
        end

        def format_error(finding)
          "#{finding[:file]}:#{finding[:line]}: Missing template '#{finding[:template]}'"
        end
      end
    end
  end
end
