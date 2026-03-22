# frozen_string_literal: true

module Ace
  module Demo
    module Molecules
      class TapeResolver
        def initialize(gem_root: Demo.gem_root, home_dir: Dir.home, cwd: Dir.pwd)
          @gem_root = gem_root
          @home_dir = home_dir
          @cwd = cwd
        end

        def resolve(tape_ref)
          direct_path = File.expand_path(tape_ref, @cwd)
          return direct_path if File.file?(direct_path)

          candidates = search_dirs.map do |dir|
            candidate_names(tape_ref).map { |name| File.join(dir, name) }
          end
          candidates.flatten!

          match = candidates.find { |path| File.file?(path) }
          return match if match

          raise TapeNotFoundError, missing_message(tape_ref)
        end

        def search_dirs
          Atoms::TapeSearchDirs.build(cwd: @cwd, home_dir: @home_dir, gem_root: @gem_root)
        end

        private

        def candidate_names(tape_ref)
          return [tape_ref] if explicit_filename?(tape_ref)

          ["#{tape_ref}.tape.yml", "#{tape_ref}.tape.yaml", "#{tape_ref}.tape"]
        end

        def explicit_filename?(tape_ref)
          tape_ref.end_with?(".tape", ".tape.yml", ".tape.yaml", ".yml", ".yaml")
        end

        def missing_message(tape_ref)
          searched = search_dirs.join(", ")
          "Tape not found: #{tape_ref}\nSearched: #{searched}"
        end
      end
    end
  end
end
