# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require "terminal-table"
require "colorize"
require_relative "../../organisms/document_registry"
require_relative "scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        # dry-cli Command class for the status command
        #
        # This command shows document freshness and update status.
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include ScopeOptions

          desc <<~DESC.strip
            Show status of all managed documents

            Display status information for all documents tracked by ace-docs,
            including freshness, update status, and document metadata.

            Configuration:
              Global config:  ~/.ace/docs/config.yml
              Project config: .ace/docs/config.yml
              Example:        ace-docs/.ace-defaults/docs/config.yml

            Output:
              Table format with columns: path, type, status, last-updated
              Exit codes: 0 (success), 1 (error)
          DESC

          example [
            "                             # All tracked documents",
            "--type handbook              # Filter by document type",
            "--needs-update               # Show only documents needing update",
            "--freshness stale            # Filter by freshness status",
            "--freshness current          # Filter by freshness status",
            "--package ace-docs           # Scope to one package",
            "--glob 'ace-docs/**/*.md'    # Scope by glob"
          ]

          option :type, type: :string, desc: "Filter by document type"
          option :needs_update, type: :boolean, desc: "Show only documents needing update"
          option :freshness, type: :string, desc: "Filter by freshness status (current/stale/outdated)"
          option :package, type: :array, desc: "Scope to package(s), e.g. --package ace-docs"
          option :glob, type: :array, desc: "Scope by glob(s), e.g. --glob 'ace-docs/**/*.md'"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            execute_status(options)
          end

          private

          def execute_status(options)
            registry = create_registry(options)
            documents = filter_documents(registry, options)

            if documents.empty?
              $stderr.puts "No managed documents found."
              return
            end

            display_status(documents)
            display_summary(documents, registry)
          rescue StandardError => e
            $stderr.puts "Error showing status: #{e.message}"
            $stderr.puts e.backtrace.join("\n") if debug?(options)
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def create_registry(options)
            project_root = options[:project_root]
            scope_globs = normalized_scope_globs(options, project_root: project_root)

            Ace::Docs::Organisms::DocumentRegistry.new(
              project_root: project_root,
              scope_globs: scope_globs
            )
          end

          def filter_documents(registry, options)
            documents = registry.all

            # Filter by type if specified
            if options[:type]
              documents = documents.select { |doc| doc.doc_type == options[:type] }
            end

            # Filter by needs-update if specified
            if options[:needs_update]
              documents = documents.select(&:needs_update?)
            end

            # Filter by freshness if specified
            if options[:freshness]
              status = options[:freshness].to_sym
              documents = documents.select { |doc| doc.freshness_status == status }
            end

            documents.sort_by(&:path)
          end

          def display_status(documents)
            # Group documents by directory
            grouped = documents.group_by { |doc| File.dirname(doc.relative_path || doc.path) }

            puts "\nManaged Documents (#{documents.size} found)\n"

            grouped.each do |group_name, group_docs|
              puts "\n#{format_group_name(group_name)}:".cyan
              display_group_table(group_docs)
            end
          end

          def display_group_table(documents)
            rows = documents.map do |doc|
              [
                status_icon(doc),
                doc.display_name,
                doc.doc_type || "-",
                format_date(doc.last_updated),
                freshness_indicator(doc)
              ]
            end

            table = Terminal::Table.new do |t|
              t.headings = ["", "Document", "Type", "Last Updated", "Status"]
              t.rows = rows
              t.style = { border_top: false, border_bottom: false }
            end

            puts table
          end

          def display_summary(documents, registry)
            stats = registry.stats
            needs_update = documents.count(&:needs_update?)

            puts "\nSummary:"
            puts "  Total: #{documents.size} documents"
            puts "  Needing update: #{needs_update}".yellow if needs_update > 0

            # Show by type
            if stats[:by_type].any?
              puts "  By type:"
              stats[:by_type].each do |type, count|
                puts "    #{type}: #{count}"
              end
            end

            # Show by freshness
            freshness_counts = documents.group_by(&:freshness_status).transform_values(&:size)
            if freshness_counts.any?
              puts "  By freshness:"
              freshness_counts.each do |status, count|
                color = case status
                        when :current then :green
                        when :stale then :yellow
                        when :outdated then :red
                        else :white
                        end
                puts "    #{status}: #{count}".colorize(color)
              end
            end
          end

          def status_icon(doc)
            case doc.freshness_status
            when :current
              "✓".green
            when :stale
              "⚠".yellow
            when :outdated
              "✗".red
            else
              "?".light_black
            end
          end

          def format_date(date)
            return "-" unless date

            # Normalize Time to Date for age calculation
            date_for_calc = date.is_a?(Time) ? date.to_date : date
            days_ago = (Date.today - date_for_calc).to_i

            # Display with time component when available (ISO 8601 for Time objects)
            date_str = if date.respond_to?(:hour)
                         date.utc.strftime("%Y-%m-%dT%H:%M:%SZ")  # ISO 8601 UTC
                       else
                         date.strftime("%Y-%m-%d")  # Date-only
                       end

            if days_ago == 0
              "#{date_str} (today)".green
            elsif days_ago == 1
              "#{date_str} (1d ago)".green
            elsif days_ago <= 7
              "#{date_str} (#{days_ago}d ago)".yellow
            else
              "#{date_str} (#{days_ago}d ago)".red
            end
          end

          def freshness_indicator(doc)
            if doc.needs_update?
              "needs update".red
            elsif doc.freshness_status == :current
              "current"
            elsif doc.freshness_status == :stale
              "getting stale".yellow
            else
              doc.freshness_status.to_s
            end
          end

          def format_group_name(name)
            # Format group names - keep original directory names intact
            case name
            when nil, ""
              "Root"
            else
              # Just return the directory name as-is (don't capitalize)
              name.to_s
            end
          end
        end
      end
    end
  end
end
