# frozen_string_literal: true

require "terminal-table"
require "colorize"
require_relative "../organisms/document_registry"

module Ace
  module Docs
    module Commands
      # Shows document freshness and update status
      class StatusCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
        end

        def execute
          documents = filter_documents

          if documents.empty?
            puts "No managed documents found.".yellow
            return
          end

          display_status(documents)
          display_summary(documents)
        end

        private

        def filter_documents
          documents = @registry.all

          # Filter by type if specified
          if @options[:type]
            documents = documents.select { |doc| doc.doc_type == @options[:type] }
          end

          # Filter by needs-update if specified
          if @options[:needs_update]
            documents = documents.select(&:needs_update?)
          end

          # Filter by freshness if specified
          if @options[:freshness]
            status = @options[:freshness].to_sym
            documents = documents.select { |doc| doc.freshness_status == status }
          end

          documents.sort_by(&:path)
        end

        def display_status(documents)
          # Group documents by type or directory
          grouped = if @options[:group_by] == "type"
                      documents.group_by(&:doc_type)
                    else
                      documents.group_by { |doc| File.dirname(doc.relative_path || doc.path) }
                    end

          puts "\nManaged Documents (#{documents.size} found)\n".bold

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

        def display_summary(documents)
          stats = @registry.stats
          needs_update = documents.count(&:needs_update?)

          puts "\nSummary:".bold
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

          days_ago = (Date.today - date).to_i
          date_str = date.strftime("%Y-%m-%d")

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
            "current".green
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