# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Compressor
    module CLI
      module Commands
        class Compress < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Compress markdown/text files into a minimal ContextPack/1"

          argument :sources, required: false, type: :array, desc: "File or directory paths"
          option :mode, type: :string, default: "exact", desc: "Compression mode (exact)"
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

            sources = options[:sources] || []
            if sources.empty?
              raise Ace::Core::CLI::Error,
                    "Missing input path. Usage: ace-compressor <file-or-dir> [more-paths...] --mode exact"
            end

            mode = (options[:mode] || "exact").to_s
            unless mode == "exact"
              raise Ace::Core::CLI::Error, "Unsupported mode '#{mode}'. Only --mode exact is available in this slice"
            end

            runner = Ace::Compressor::Organisms::CompressionRunner.new(
              sources,
              mode: mode,
              output: options[:output],
              format: options[:format],
              verbose: !!options[:verbose]
            )
            result = runner.call
            if options[:verbose]
              result[:ignored_paths].each { |path| $stderr.puts "Ignoring unsupported file: #{path}" }
            end
            puts result[:console_output]
          rescue Ace::Compressor::Error => e
            raise Ace::Core::CLI::Error, e.message
          end
        end
      end
    end
  end
end
