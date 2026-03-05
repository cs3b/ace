# frozen_string_literal: true

module Ace
  module Demo
    module Molecules
      class TapeScanner
        def initialize(gem_root: Demo.gem_root, home_dir: Dir.home, cwd: Dir.pwd, parser: Atoms::TapeMetadataParser)
          @gem_root = gem_root
          @home_dir = home_dir
          @cwd = cwd
          @parser = parser
        end

        def list
          discovered = {}

          search_dirs.each do |dir|
            next unless Dir.exist?(dir)

            Dir.glob(File.join(dir, "*.tape")).sort.each do |path|
              name = File.basename(path, ".tape")
              next if discovered.key?(name)

              discovered[name] = build_record(name, path)
            end
          end

          discovered.keys.sort.map { |name| discovered[name] }
        end

        def find(tape_ref)
          direct_path = File.expand_path(tape_ref, @cwd)
          if File.exist?(direct_path) && File.file?(direct_path)
            name = File.basename(direct_path, ".tape")
            return build_record(name, direct_path)
          end

          lookup_name = File.basename(tape_ref, ".tape")
          match = find_in_search_dirs(lookup_name)
          return match if match

          raise TapeNotFoundError, missing_message(tape_ref)
        end

        private

        def search_dirs
          Atoms::TapeSearchDirs.build(cwd: @cwd, home_dir: @home_dir, gem_root: @gem_root)
        end

        def build_record(name, path)
          content = File.read(path)
          metadata = @parser.parse(content)

          {
            name: name,
            path: path,
            display_path: display_path(path),
            source: "#{display_path(File.dirname(path))}/",
            metadata: metadata,
            description: metadata["description"],
            content: content
          }
        end

        def find_in_search_dirs(name)
          search_dirs.each do |dir|
            path = File.join(dir, "#{name}.tape")
            next unless File.file?(path)

            return build_record(name, path)
          end

          nil
        end

        def display_path(path)
          expanded = File.expand_path(path)

          if inside?(expanded, @cwd)
            relative_to(@cwd, expanded)
          elsif inside?(expanded, @gem_root)
            relative_to(@gem_root, expanded)
          elsif inside?(expanded, @home_dir)
            relative_to(@home_dir, expanded, "~")
          else
            expanded
          end
        end

        def relative_to(base, path, prefix = nil)
          suffix = path.delete_prefix("#{File.expand_path(base)}/")
          return suffix if prefix.nil?

          [prefix, suffix].join("/")
        end

        def inside?(path, base)
          path == File.expand_path(base) || path.start_with?("#{File.expand_path(base)}/")
        end

        def missing_message(tape_ref)
          names = list.map { |item| item[:name] }
          available = names.empty? ? "(none)" : names.join(", ")
          "Tape not found: #{tape_ref}\nAvailable tapes: #{available}"
        end
      end
    end
  end
end
