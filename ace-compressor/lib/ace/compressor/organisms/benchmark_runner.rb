# frozen_string_literal: true

require "json"
require "pathname"

module Ace
  module Compressor
    module Organisms
      class BenchmarkRunner
        SUPPORTED_FORMATS = %w[table json].freeze
        SUPPORTED_MODES = CompressionRunner::SUPPORTED_MODES

        def initialize(paths, modes: nil, format: "table", verbose: false)
          @paths = Array(paths)
          @modes = parse_modes(modes)
          @format = (format || "table").to_s
          @verbose = verbose
          @resolver = ExactCompressor.new(paths, verbose: verbose)
          @retention = Ace::Compressor::Atoms::RetentionReporter.new
        end

        def call
          raise Ace::Compressor::Error, "Unsupported format '#{@format}'. Use --format table or json" unless SUPPORTED_FORMATS.include?(@format)

          sources = @resolver.resolve_sources
          per_source = sources.map { |source| benchmark_source(source) }
          {
            "sources" => per_source,
            "summary" => summarize(per_source)
          }
        end

        def render(report)
          return JSON.pretty_generate(report) if @format == "json"

          render_table(report.fetch("sources"))
        end

        private

        def parse_modes(modes)
          values = Array(modes || SUPPORTED_MODES)
          values = values.flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?)
          values = SUPPORTED_MODES if values.empty?
          unknown = values - SUPPORTED_MODES
          raise Ace::Compressor::Error, "Unsupported modes: #{unknown.join(', ')}" unless unknown.empty?

          values.uniq
        end

        def benchmark_source(source)
          exact_result = run_mode(source, "exact")
          reference_content = exact_result["content"]

          {
            "source" => relative_source(source),
            "modes" => @modes.map { |mode| mode_report(source, mode, reference_content, exact_result) }
          }
        end

        def mode_report(source, mode, reference_content, exact_result)
          result = mode == "exact" ? exact_result : run_mode(source, mode)
          return result.merge("mode" => mode) unless result["status"] == "ok"

          metrics = @retention.compare(reference_content: reference_content, candidate_content: result.fetch("content"))
          metadata = result.fetch("metadata")

          {
            "mode" => mode,
            "status" => "ok",
            "cache" => result.fetch("cache_hit") ? "hit" : "miss",
            "output_path" => result.fetch("output_path"),
            "original_bytes" => metadata.fetch("original_bytes"),
            "original_lines" => metadata.fetch("original_lines"),
            "packed_bytes" => metadata.fetch("packed_bytes"),
            "packed_lines" => metadata.fetch("packed_lines"),
            "byte_change_percent" => percent_change(metadata.fetch("original_bytes"), metadata.fetch("packed_bytes")),
            "line_change_percent" => percent_change(metadata.fetch("original_lines"), metadata.fetch("packed_lines")),
            "coverage" => metrics
          }
        end

        def run_mode(source, mode)
          result = CompressionRunner.new([source], mode: mode, format: "path", verbose: @verbose).call
          {
            "status" => result[:exit_code].to_i.zero? ? "ok" : "nonzero",
            "cache_hit" => result[:cache_hit],
            "metadata" => result[:metadata],
            "output_path" => result[:output_path],
            "content" => File.read(result[:output_path]),
            "refusal_lines" => result[:refusal_lines],
            "fallback_lines" => result[:fallback_lines]
          }
        rescue StandardError => e
          {
            "status" => "error",
            "error" => e.message
          }
        end

        def render_table(per_source)
          rows = [["Source", "Mode", "Cache", "Bytes", "Lines", "Secs", "Prot", "Struct", "Loss", "Status"]]

          per_source.each do |entry|
            entry.fetch("modes").each do |mode|
              if mode.fetch("status") != "ok"
                rows << [entry.fetch("source"), mode.fetch("mode"), "-", "-", "-", "-", "-", "-", "-", mode.fetch("status")]
                next
              end

              coverage = mode.fetch("coverage")
              rows << [
                entry.fetch("source"),
                mode.fetch("mode"),
                mode.fetch("cache"),
                format_change(mode.fetch("byte_change_percent")),
                format_change(mode.fetch("line_change_percent")),
                coverage_ratio(coverage.fetch("sections")),
                coverage_ratio(coverage.fetch("protected")),
                coverage_ratio(coverage.fetch("structured")),
                total_loss_markers(coverage.fetch("loss_markers")),
                mode.fetch("status")
              ]
            end
          end

          render_rows(rows)
        end

        def render_rows(rows)
          widths = rows.transpose.map { |column| column.map { |cell| cell.to_s.length }.max }
          rows.map.with_index do |row, index|
            line = row.each_with_index.map { |cell, column| cell.to_s.ljust(widths[column]) }.join("  ")
            index == 0 ? "#{line}\n#{widths.map { |width| '-' * width }.join('  ')}" : line
          end.join("\n")
        end

        def coverage_ratio(metric)
          "#{metric.fetch('retained')}/#{metric.fetch('total')} (#{metric.fetch('percent')}%)"
        end

        def total_loss_markers(markers)
          markers.values.sum
        end

        def percent_change(original, packed)
          return 0.0 if original.to_f.zero?

          (((packed.to_f - original.to_f) / original.to_f) * 100.0).round(1)
        end

        def format_change(value)
          format("%+.1f%%", value)
        end

        def summarize(per_source)
          rows = per_source.flat_map { |entry| entry.fetch("modes") }.select { |row| row.fetch("status") == "ok" }
          {
            "sources" => per_source.size,
            "rows" => rows.size
          }
        end

        def relative_source(source)
          Pathname.new(File.expand_path(source)).relative_path_from(Pathname.new(Dir.pwd)).to_s
        rescue ArgumentError
          source
        end
      end
    end
  end
end
