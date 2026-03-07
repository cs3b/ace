# frozen_string_literal: true

module Ace
  module Compressor
    module Models
      class ContextPack
        SCHEMA = "ContextPack/3"

        def self.escape(value)
          value.to_s.gsub("|", "\\|").gsub("\n", " ").strip
        end

        def self.header(mode)
          "H|#{SCHEMA}|#{escape(mode)}"
        end

        def self.file_line(source)
          "FILE|#{escape(source)}"
        end

        def self.section_line(title)
          "SEC|#{escape(title)}"
        end

        def self.summary_line(text)
          "SUMMARY|#{escape(text)}"
        end

        def self.fact_line(text)
          "FACT|#{escape(text)}"
        end

        def self.rule_line(text)
          "RULE|#{escape(text)}"
        end

        def self.constraint_line(text)
          "CONSTRAINT|#{escape(text)}"
        end

        def self.problems_line(items)
          values = Array(items).map { |item| escape(item) }.join(",")
          "PROBLEMS|[#{values}]"
        end

        def self.list_line(list_key, items)
          values = Array(items).map { |item| escape(item) }.join(",")
          key = list_key.to_s.strip
          key = "items" if key.empty?
          "LIST|#{escape(key)}|[#{values}]"
        end

        def self.example_line(tool)
          "EXAMPLE|#{escape("tool=#{tool}")}"
        end

        def self.cmd_line(command)
          "CMD|#{escape(command)}"
        end

        def self.files_line(label, files)
          "FILES|#{escape(label)}|[#{Array(files).map { |value| escape(value) }.join(',')}]"
        end

        def self.tree_line(label, tree)
          "TREE|#{escape(label)}|#{escape(tree)}"
        end

        def self.code_line(language, code)
          language_value = language.to_s.strip.empty? ? "code" : language.to_s.strip
          "CODE|#{escape(language_value)}|#{escape(code)}"
        end

        def self.table_line(rows)
          "TABLE|#{escape(rows)}"
        end

        def self.unresolved_line(kind, raw)
          "U|#{escape(kind)}|#{escape(raw)}"
        end

        # Backward-compatible helpers retained for call-site migration only.
        # Exact-mode now uses context-free output records without source IDs.
        def self.source_line(source_id, source); file_line(source); end

        def self.heading_line(_source_id, _level, title); section_line(title); end

        def self.fact_line_for_source(_source_id, text); fact_line(text); end

        def self.table_line_for_source(_source_id, rows); table_line(rows); end

        def self.unresolved_line_for_source(_source_id, kind, raw); unresolved_line(kind, raw); end

        def self.fallback_line(_source_id, _kind, raw); "CODE|fallback|#{escape(raw)}"; end
      end
    end
  end
end
