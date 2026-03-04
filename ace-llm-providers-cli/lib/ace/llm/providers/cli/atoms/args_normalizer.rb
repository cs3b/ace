# frozen_string_literal: true

require "shellwords"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class ArgsNormalizer
            def normalize_cli_args(cli_args)
              return [] if cli_args.nil?

              args = begin
                if cli_args.is_a?(String)
                  Shellwords.split(cli_args)
                else
                  Array(cli_args).flat_map { |a| Shellwords.split(a.to_s) }
                end
              rescue ArgumentError => e
                raise ArgumentError, "Malformed --cli-args '#{cli_args}': #{e.message}"
              end

              args = args.compact.map(&:to_s).map(&:strip).reject(&:empty?)

              normalized = []
              previous_flag = false
              seen_sentinel = false

              args.each do |arg|
                if seen_sentinel
                  normalized << arg
                  next
                end

                if arg == "--"
                  normalized << arg
                  seen_sentinel = true
                  next
                end

                if arg.start_with?("-")
                  normalized << arg
                  previous_flag = !arg.include?("=")
                  next
                end

                if previous_flag
                  normalized << arg
                else
                  normalized << "--#{arg}"
                end

                previous_flag = false
              end

              normalized
            end
          end
        end
      end
    end
  end
end
