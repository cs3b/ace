# frozen_string_literal: true

require "fileutils"

module Ace
  module Demo
    module Molecules
      class TapeWriter
        def initialize(cwd: Dir.pwd)
          @cwd = cwd
        end

        def write(name:, content:, force: false, extension: ".tape")
          path = tape_path(name, extension: extension)

          if File.exist?(path) && !force
            raise TapeAlreadyExistsError, "Tape already exists: #{path}\nUse --force to overwrite."
          end

          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)

          path
        end

        private

        def tape_path(name, extension:)
          File.join(@cwd, ".ace", "demo", "tapes", "#{name}#{extension}")
        end
      end
    end
  end
end
