# frozen_string_literal: true

require "fileutils"

module Ace
  module Demo
    module Molecules
      class TapeWriter
        def initialize(cwd: Dir.pwd)
          @cwd = cwd
        end

        def write(name:, content:, force: false)
          path = tape_path(name)

          if File.exist?(path) && !force
            raise TapeAlreadyExistsError, "Tape already exists: #{path}\nUse --force to overwrite."
          end

          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)

          path
        end

        private

        def tape_path(name)
          File.join(@cwd, ".ace", "demo", "tapes", "#{name}.tape")
        end
      end
    end
  end
end
