# frozen_string_literal: true

require "pathname"
require_relative "../atoms/report_path_resolver"

module Ace
  module TestRunner
    module Molecules
      module FailedPackageReporter
        module_function

        def format_for_display(package)
          directory = package[:report_dir] || package["report_dir"]
          directory ? "    → See #{relative_or_absolute(directory)}" : "    → No saved report"
        end

        def format_for_markdown(package)
          directory = package[:report_dir] || package["report_dir"]
          directory ? "- Report: `#{relative_or_absolute(directory)}`" : "- No saved report"
        end

        class << self
          private

          def debug_mode?
            ENV["DEBUG"]
          end

          def relative_or_absolute(path)
            Pathname.new(path).relative_path_from(Dir.pwd).to_s
          rescue => e
            warn "Failed to calculate relative path: #{e.message}" if debug_mode?
            path
          end
        end
      end
    end
  end
end
