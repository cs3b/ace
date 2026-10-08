# frozen_string_literal: true

require_relative "../errors"
require "json"
require "securerandom"
require "ace/runtime/molecules/protected_socket"

module Ace
  module Herdr
    module Molecules
      # Operational admission metadata only; DeliveryRecord remains the event ledger.
      class InboxContextStore
        LIMIT = 1_048_576
        class AlreadyProvisioned < ValidationError; end
        class ClosedObject < Hash
          def []=(key, value)
            raise ValidationError, "duplicate context field" if key?(key)
            super
          end
        end

        def self.decode(bytes, limit: LIMIT)
          raise ValidationError, "context bytes exceed bounds" unless bytes.is_a?(String) && bytes.bytesize.between?(1, limit)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          raise ValidationError, "context bytes are not UTF-8" unless text.valid_encoding?
          decoded = JSON.parse(text, object_class: ClosedObject, create_additions: false, max_nesting: 16,
            allow_nan: false, allow_comments: false, allow_duplicate_key: false)
          # ClosedObject detects duplicates while decoding, not subsequent CAS updates.
          JSON.parse(JSON.generate(decoded), create_additions: false)
        rescue JSON::ParserError, JSON::NestingError
          raise ValidationError, "context metadata is malformed"
        end

        def initialize(root:, uid:, protection: Ace::Runtime::Molecules::ProtectedSocket)
          @root, @uid, @protection = root, uid, protection
          @mutex = Mutex.new
          verify_root!
          @lease = open_private(".context-owner.lock", create: true)
          unless @lease.flock(File::LOCK_EX | File::LOCK_NB)
            @lease.close
            raise ValidationError, "context owner is already active"
          end
        end

        # Explicit installer/bootstrap operation. Restart never initializes a missing file.
        def provision!(data)
          @mutex.synchronize do
            ensure_open!
            bytes = encode(data)
            File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
              file.write(bytes)
              file.flush
              file.fsync
            end
            fsync_root!
          end
        rescue Errno::EEXIST
          raise AlreadyProvisioned, "context metadata already exists"
        rescue SystemCallError
          raise ValidationError, "context metadata provisioning refused"
        end

        def transaction
          @mutex.synchronize do
            ensure_open!
            verify_root!
            state = read!
            before = JSON.generate(state)
            result = yield state
            persist!(state) unless JSON.generate(state) == before
            result
          end
        rescue SystemCallError, IOError
          raise ValidationError, "context metadata is unavailable"
        end

        def close
          @mutex.synchronize do
            @lease&.close
            @lease = nil
          end
        end

        private

        def ensure_open!
          raise ValidationError, "context owner is closed" unless @lease && !@lease.closed?
          unless identity(@lease.stat) == identity(File.lstat(File.join(@root, ".context-owner.lock")))
            raise ValidationError, "context owner lock changed"
          end
        end

        def verify_root!
          @protection.root_path!(@root, directory: true, owner: @uid)
          stat = File.lstat(@root)
          unless stat.directory? && !stat.symlink? && stat.uid == @uid && (stat.mode & 0o077).zero?
            raise ValidationError, "context state root is not private"
          end
          current = [stat.dev, stat.ino, stat.uid, stat.mode]
          raise ValidationError, "context state root changed" if @root_identity && current != @root_identity
          @root_identity ||= current
        end

        def path = File.join(@root, ".context-control.json")

        def open_private(name, create: false)
          flags = File::RDWR | File::NOFOLLOW | File::NONBLOCK | (create ? File::CREAT : 0)
          file = File.open(File.join(@root, name), flags, 0o600)
          begin
            file.close_on_exec = true
            stat = file.stat
            unless stat.file? && stat.uid == @uid && (stat.mode & 0o077).zero? &&
                identity(stat) == identity(File.lstat(File.join(@root, name)))
              raise ValidationError, "context metadata file is unsafe"
            end
            file
          rescue Exception
            file.close
            raise
          end
        end

        def read!
          file = open_private(".context-control.json")
          self.class.decode(file.read(LIMIT + 1))
        ensure
          file&.close
        end

        def encode(data)
          bytes = JSON.generate(data)
          raise ValidationError, "context metadata exceeds bounds" unless bytes.bytesize.between?(1, LIMIT)
          bytes
        end

        def persist!(data)
          bytes = encode(data)
          temporary = File.join(@root, ".context-control.#{SecureRandom.hex(16)}.tmp")
          File.open(temporary, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
            file.write(bytes)
            file.flush
            file.fsync
          end
          verify_root!
          File.rename(temporary, path)
          fsync_root!
        ensure
          File.unlink(temporary) if temporary && File.exist?(temporary)
        end

        def fsync_root!
          File.open(@root, File::RDONLY | File::NOFOLLOW) { |directory| directory.fsync }
        end

        def identity(stat) = [stat.dev, stat.ino, stat.uid, stat.mode]
      end
    end
  end
end
