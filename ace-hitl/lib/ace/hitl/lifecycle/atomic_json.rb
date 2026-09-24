# frozen_string_literal: true

require "json"
require "fileutils"

module Ace
  module Hitl
    module Lifecycle
      # Durable, permission-preserving JSON record writes (port of
      # atomic_json): O_EXCL|O_NOFOLLOW tempfile in the target directory,
      # fsync, chmod, chown, rename. Ownership transitions go through the
      # injectable ownership strategy; production performs real chown(2),
      # tests map names onto the current identity (spec 8wm.t.y21 §2).
      module AtomicJson
        Ownership = Struct.new(:uid, :gid)

        DEFAULT_OWNERSHIP = Object.new.tap do |strategy|
          strategy.define_singleton_method(:chown) do |path, ownership|
            File.chown(ownership.uid, ownership.gid, path) if ownership
          end
        end.freeze

        module_function

        # mode is an Integer permission bits value; ownership nil keeps
        # the current identity.
        def call(path, value, mode:, ownership: nil, ownership_strategy: DEFAULT_OWNERSHIP)
          path = Pathname.new(path)
          path.parent.mkpath
          temporary = path.parent.join(".#{path.basename}.tmp.#{$PROCESS_ID}")
          flags = File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW
          fd = IO.sysopen(temporary, flags, mode)
          begin
            io = IO.for_fd(fd, mode: "w")
            begin
              io.write(JSON.generate(value))
              io.write("\n")
              io.flush
              io.fsync
            ensure
              io.close
            end
          rescue
            begin
              temporary.unlink
            rescue
              nil
            end
            raise
          end
          File.chmod(mode, temporary)
          ownership_strategy.chown(temporary, ownership)
          File.rename(temporary, path)
        ensure
          temporary.unlink if temporary&.exist?
        end

        def read(path)
          JSON.parse(File.read(path))
        rescue SystemCallError, JSON::ParserError
          nil
        end
      end
    end
  end
end
