# frozen_string_literal: true

require "yaml"
require "fileutils"
require "ace/b36ts"

module Ace
  module Docs
    module Models
      # Data model for analysis reports
      class AnalysisReport
        attr_accessor :generated, :since, :documents, :analysis, :statistics

        def initialize(attributes = {})
          @generated = attributes[:generated] || Time.now.utc.iso8601
          @since = attributes[:since]
          @documents = attributes[:documents] || []
          @analysis = attributes[:analysis]
          @statistics = attributes[:statistics] || {}
        end

        # Convert report to markdown format
        # @return [String] Markdown-formatted report
        def to_markdown
          frontmatter = build_frontmatter
          body = @analysis || "No analysis available"

          <<~MARKDOWN
            ---
            #{frontmatter.to_yaml.strip}
            ---

            #{body}
          MARKDOWN
        end

        # Save report to cache directory
        # @param cache_dir [String] Cache directory path
        # @return [String] Path to saved file
        def save_to_cache(cache_dir = nil)
          cache_dir ||= Ace::Docs.config["cache_dir"] || ".ace-local/docs"
          FileUtils.mkdir_p(cache_dir)

          compact_id = Ace::B36ts.encode(Time.now)
          filename = "analysis-#{compact_id}.md"
          filepath = File.join(cache_dir, filename)

          File.write(filepath, to_markdown)
          filepath
        end

        # Convert to hash
        # @return [Hash] Report as hash
        def to_h
          {
            generated: @generated,
            since: @since,
            documents: documents_list,
            analysis: @analysis,
            statistics: @statistics
          }
        end

        # Load report from file
        # @param filepath [String] Path to report file
        # @return [AnalysisReport] Loaded report
        def self.load_from_file(filepath)
          content = File.read(filepath)

          # Parse YAML frontmatter
          if content =~ /\A---\n(.*?)\n---\n(.*)/m
            frontmatter = YAML.safe_load(Regexp.last_match(1))
            body = Regexp.last_match(2)

            new(
              generated: frontmatter["generated"],
              since: frontmatter["since"],
              documents: parse_documents(frontmatter["document_list"]),
              analysis: body.strip,
              statistics: frontmatter["statistics"] || {}
            )
          else
            # No frontmatter, treat entire content as analysis
            new(analysis: content)
          end
        end

        private

        def build_frontmatter
          {
            "generated" => @generated,
            "since" => @since,
            "documents" => @documents.size,
            "document_list" => documents_list,
            "statistics" => @statistics
          }
        end

        def documents_list
          @documents.map do |doc|
            if doc.respond_to?(:relative_path)
              doc.relative_path || doc.path
            elsif doc.is_a?(Hash)
              doc["path"] || doc[:path]
            else
              doc.to_s
            end
          end
        end

        def self.parse_documents(doc_list)
          return [] unless doc_list

          doc_list.map { |path| { path: path } }
        end
      end
    end
  end
end