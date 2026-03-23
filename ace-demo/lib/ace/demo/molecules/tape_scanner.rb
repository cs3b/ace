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

            discover_paths(dir).each do |path|
              name = logical_name(path)
              next if discovered.key?(name)

              discovered[name] = build_record(name, path)
            end
          end

          discovered.keys.sort.map { |name| discovered[name] }
        end

        def find(tape_ref)
          direct_path = File.expand_path(tape_ref, @cwd)
          if File.exist?(direct_path) && File.file?(direct_path)
            name = logical_name(direct_path)
            return build_record(name, direct_path)
          end

          lookup_name = logical_name(tape_ref)
          match = find_in_search_dirs(lookup_name, tape_ref)
          return match if match

          raise TapeNotFoundError, missing_message(tape_ref)
        end

        private

        def search_dirs
          Atoms::TapeSearchDirs.build(cwd: @cwd, home_dir: @home_dir, gem_root: @gem_root)
        end

        def discover_paths(dir)
          patterns = [File.join(dir, "*.tape.yml"), File.join(dir, "*.tape.yaml"), File.join(dir, "*.tape")]
          patterns.flat_map { |pattern| Dir.glob(pattern).sort }
        end

        def build_record(name, path)
          content = File.read(path)
          format = path.end_with?(".tape.yml", ".tape.yaml") ? "yaml" : "tape"
          metadata = extract_metadata(path: path, content: content, format: format)

          {
            name: name,
            path: path,
            display_path: display_path(path),
            source: "#{display_path(File.dirname(path))}/",
            format: format,
            metadata: metadata,
            description: metadata["description"],
            content: content
          }
        end

        def extract_metadata(path:, content:, format:)
          return @parser.parse(content) if format == "tape"

          spec = Atoms::DemoYamlParser.parse_file(path)
          {
            "description" => spec["description"],
            "tags" => spec["tags"],
            "settings" => spec["settings"],
            "scene_names" => spec.fetch("scenes", []).map { |scene| scene["name"] }.compact
          }
        rescue DemoYamlParseError => e
          {"description" => nil, "parse_error" => e.message}
        end

        def find_in_search_dirs(name, tape_ref)
          explicit = explicit_filename?(tape_ref)
          candidates = if explicit
            [tape_ref]
          else
            ["#{name}.tape.yml", "#{name}.tape.yaml", "#{name}.tape"]
          end

          search_dirs.each do |dir|
            candidates.each do |filename|
              path = File.join(dir, filename)
              next unless File.file?(path)

              return build_record(logical_name(path), path)
            end
          end

          nil
        end

        def explicit_filename?(tape_ref)
          tape_ref.end_with?(".tape", ".tape.yml", ".tape.yaml", ".yml", ".yaml")
        end

        def logical_name(path)
          File.basename(path).sub(/\.tape\.ya?ml\z/, "").sub(/\.tape\z/, "").sub(/\.ya?ml\z/, "")
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
