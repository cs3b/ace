# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Compressor
    module CLI
      module Commands
        class Benchmark < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Compare exact, compact, and agent output on live sources"

          argument :sources, required: false, type: :array, desc: "File or directory paths"
          option :modes, type: :string, desc: "Comma-delimited modes: exact,compact,agent"
          option :format, type: :string, aliases: ["-f"], desc: "Benchmark output format: table|json"
          option :verbose, type: :boolean, aliases: ["-v"], default: false, desc: "Show verbose output"

          def call(**options)
            sources = normalize_sources(options[:sources] || [])
            if sources.empty?
              raise Ace::Support::Cli::Error,
                    "Missing input path. Usage: ace-compressor benchmark <file-or-dir> [more-paths...]"
            end

            runner = Ace::Compressor::Organisms::BenchmarkRunner.new(
              sources,
              modes: options[:modes],
              format: options[:format],
              verbose: !!options[:verbose]
            )
            report = runner.call
            puts runner.render(report)
            0
          rescue Ace::Compressor::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def normalize_sources(sources)
            values = Array(sources).dup
            values.shift if values.first == "benchmark"
            values
          end
        end
      end
    end
  end
end
