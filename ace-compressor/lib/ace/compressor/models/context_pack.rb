# frozen_string_literal: true

module Ace
  module Compressor
    module Models
      class ContextPack
        SCHEMA = "ContextPack/2"

        def self.escape(value)
          value.to_s.gsub("|", "\\|").gsub("\n", " ").strip
        end

        def self.header(mode)
          "H|#{SCHEMA}|#{escape(mode)}"
        end

        def self.source_line(source_id, source)
          "S|#{source_id}|#{escape(source)}"
        end

        def self.heading_line(source_id, level, title)
          "M|#{source_id}|#{level}|#{escape(title)}"
        end

        def self.fact_line(source_id, text)
          "F|#{source_id}|#{escape(text)}"
        end

        def self.table_line(source_id, rows)
          "T|#{source_id}|#{escape(rows)}"
        end

        def self.unresolved_line(source_id, kind, raw)
          "U|#{source_id}|#{escape(kind)}|#{escape(raw)}"
        end

        def self.fallback_line(source_id, kind, raw)
          "B|#{source_id}|#{escape(kind)}|#{escape(raw)}"
        end
      end
    end
  end
end
