# frozen_string_literal: true

require "json"
require "digest"
require_relative "private_directory"

module Ace
  module Assign
    module Authority
      # Immutable requester inputs, never evidence that an operation executed.
      module RetainedInput
        module_function

        def read_file(path, limit)
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            before = file.stat
            raise ArgumentError, "retained input is not a bounded regular file" unless before.file? && before.size.between?(0, limit)
            bytes = (file.read(limit + 1) || "").b
            after, selected = file.stat, File.lstat(path)
            identity = ->(stat) { [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] }
            unless bytes.bytesize == before.size && identity.call(before) == identity.call(after) &&
                identity.call(after) == identity.call(selected) && !selected.symlink?
              raise ArgumentError, "retained input changed during read"
            end
            bytes.freeze
          end
        end

        def json(path, limit = 16_384)
          JSON.parse(read_file(path, limit), allow_duplicate_key: false, create_additions: false, max_nesting: 24)
        end

        def create_output(path)
          raise ArgumentError, "output must be a new directory path" unless path.is_a?(String) && !path.empty?
          directory = File.expand_path(path)
          Dir.mkdir(directory, 0o700)
          PrivateDirectory.verify!(directory)
          directory
        end

        def write_file(directory, name, bytes)
          raise ArgumentError, "retained filename is invalid" unless File.basename(name) == name && !%w[. ..].include?(name)
          File.open(File.join(directory, name), File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
            file.write(bytes)
            file.flush
            file.fsync
          end
          File.open(directory) { |file| file.fsync }
        end
      end
    end
  end
end
