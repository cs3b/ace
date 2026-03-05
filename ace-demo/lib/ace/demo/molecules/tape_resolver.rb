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
            name = tape_ref.end_with?(".tape") ? tape_ref : "#{tape_ref}.tape"
            File.join(dir, name)
          end

          match = candidates.find { |path| File.exist?(path) }
          return match if match

          raise TapeNotFoundError, missing_message(tape_ref)
        end

        def search_dirs
          Atoms::TapeSearchDirs.build(cwd: @cwd, home_dir: @home_dir, gem_root: @gem_root)
        end

        private

        def missing_message(tape_ref)
          searched = search_dirs.join(", ")
          "Tape not found: #{tape_ref}\nSearched: #{searched}"
        end
      end
    end
  end
end
