# frozen_string_literal: true

require "ace/support/config"

module Ace
  module TestRunner
    module Atoms
      # Resolves canonical test report directories.
      module ReportDirectoryResolver
        module_function

        DEFAULT_REPORT_ROOT = ".ace-local/test/reports"

        def resolve_report_root(raw_report_dir, explicit_cli_override:, start_path:)
          root = raw_report_dir.to_s.strip
          root = DEFAULT_REPORT_ROOT if root.empty?

          return File.expand_path(root, start_path) if explicit_cli_override

          project_root = Ace::Support::Config.find_project_root(start_path: start_path)
          base = project_root || start_path
          File.expand_path(root, base)
        end

        def infer_package_name(package_dir:, test_files:, cwd:)
          if package_dir && !package_dir.to_s.empty?
            return File.basename(File.expand_path(package_dir))
          end

          first = Array(test_files).first
          if first && (match = first.match(%r{\A(.+?)/test/}))
            return File.basename(match[1])
          end

          File.basename(File.expand_path(cwd))
        end

        def short_package_name(package_name)
          package_name.to_s.sub(/\Aace-/, "")
        end

        def resolve_package_report_dir(report_root:, package_name:)
          File.join(report_root, short_package_name(package_name))
        end
      end
    end
  end
end
