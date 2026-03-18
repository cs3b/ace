# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Compressor
    module CLI
      module Commands
        class Compress < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          SUPPORTED_MODES = %w[exact compact agent].freeze
          SUPPORTED_SOURCE_SCOPES = %w[merged per-source].freeze

          desc "Compress markdown/text files into ContextPack/3 records"

          argument :sources, required: false, type: :array, desc: "File or directory paths"
          option :mode, type: :string, default: "exact", desc: "Compression mode (exact|compact|agent)"
          option :source_scope, type: :string, default: "merged", desc: "Source handling mode (merged|per-source)"
          option :output, type: :string, aliases: ["-o"], desc: "Save output to file or directory path"
          option :format, type: :string, aliases: ["-f"], desc: "Console output format: path|stdio|stats"
          option :version, type: :boolean, desc: "Show version information"
          option :quiet, type: :boolean, aliases: ["-q"], default: false, desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: ["-v"], default: false, desc: "Show verbose output"
          option :debug, type: :boolean, aliases: ["-d"], default: false, desc: "Show debug output"

          def call(**options)
            if options[:version]
              puts "ace-compressor #{Ace::Compressor::VERSION}"
              return 0
            end

            sources = normalize_sources(options[:sources] || [])
            if sources.empty?
              raise Ace::Support::Cli::Error,
                    "Missing input path. Usage: ace-compressor <file-or-dir> [more-paths...] --mode <exact|compact|agent>"
            end

            mode = (options[:mode] || "exact").to_s
            unless SUPPORTED_MODES.include?(mode)
              raise Ace::Support::Cli::Error, "Unsupported mode '#{mode}'. Use --mode exact, --mode compact, or --mode agent"
            end
            source_scope = (options[:source_scope] || "merged").to_s
            unless SUPPORTED_SOURCE_SCOPES.include?(source_scope)
              raise Ace::Support::Cli::Error,
                    "Unsupported source scope '#{source_scope}'. Use --source-scope merged or --source-scope per-source"
            end

            runner = Ace::Compressor::Organisms::CompressionRunner.new(
              sources,
              mode: mode,
              source_scope: source_scope,
              output: options[:output],
              format: options[:format],
              verbose: !!options[:verbose]
            )
            result = runner.call
            if options[:verbose]
              result[:ignored_paths].each { |path| $stderr.puts "Ignoring unsupported file: #{path}" }
            end
            puts result[:console_output]
            if result[:exit_code].to_i.nonzero?
              raise Ace::Support::Cli::Error, refusal_message_for(mode)
            end
          rescue Ace::Compressor::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def normalize_sources(sources)
            values = Array(sources).dup
            values.shift if values.first == "compress"
            values
          end

          def refusal_message_for(mode)
            if mode == "compact"
              "One or more sources were refused in compact mode. Retry refused sources with --mode exact"
            else
              "One or more sources were refused in #{mode} mode. Retry refused sources with --mode exact"
            end
          end
        end
      end
    end
  end
end
