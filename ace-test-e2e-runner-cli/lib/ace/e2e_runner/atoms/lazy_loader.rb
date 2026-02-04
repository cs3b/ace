# frozen_string_literal: true

module Ace
  module E2eRunner
    module Atoms
      class LazyLoader
        def self.load_formatter(format)
          case format
          when "progress"
            require_relative "../formatters/progress_formatter"
            Formatters::ProgressFormatter
          when "progress-file"
            require_relative "../formatters/progress_file_formatter"
            Formatters::ProgressFileFormatter
          when "json"
            require_relative "../formatters/json_formatter"
            Formatters::JsonFormatter
          else
            raise Ace::E2eRunner::Error, "Unknown format: #{format}"
          end
        end
      end
    end
  end
end
