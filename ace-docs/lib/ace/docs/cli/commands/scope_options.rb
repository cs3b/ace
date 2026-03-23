# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module Docs
    module CLI
      module Commands
        # Shared scope parsing helpers for package/glob scoped document selection.
        module ScopeOptions
          private

          def normalized_scope_globs(options, project_root: nil)
            root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            package_globs = Array(options[:package]).compact.map { |value| normalize_package_scope(value, root) }
            direct_globs = Array(options[:glob]).compact.map { |value| normalize_glob_scope(value, root) }
            (package_globs + direct_globs).uniq
          end

          def scope_options_present?(options)
            Array(options[:package]).any? || Array(options[:glob]).any?
          end

          def path_in_scope?(path, scope_globs, project_root:)
            return true if scope_globs.nil? || scope_globs.empty?

            expanded = File.expand_path(path, project_root)
            relative = begin
              expanded.delete_prefix("#{File.expand_path(project_root)}/")
            rescue
              path.to_s
            end

            scope_globs.any? do |pattern|
              File.fnmatch?(pattern, relative, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
            end
          end

          def normalize_package_scope(raw_value, project_root)
            value = raw_value.to_s.strip
            raise ArgumentError, "--package cannot be blank" if value.empty?

            path = File.join(project_root, value)
            raise ArgumentError, "Unknown package for --package: #{value}" unless Dir.exist?(path)

            "#{value.chomp("/")}/**/*.md"
          end

          def normalize_glob_scope(raw_value, project_root)
            value = raw_value.to_s.strip.sub(%r{\A\./}, "")
            raise ArgumentError, "--glob cannot be blank" if value.empty?

            return value if wildcard_pattern?(value)
            return value if value.end_with?(".md")

            directory_path = File.join(project_root, value)
            if value.end_with?("/") || Dir.exist?(directory_path)
              return "#{value.chomp("/")}/**/*.md"
            end

            "#{value}/**/*.md"
          end

          def wildcard_pattern?(value)
            value.match?(/[*?\[\]{]/)
          end
        end
      end
    end
  end
end
