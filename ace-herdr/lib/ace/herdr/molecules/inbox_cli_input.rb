# frozen_string_literal: true
require_relative "inbox_context_store"

module Ace
  module Herdr
    module Molecules
      module InboxCliInput
        module_function
        def read(path, limit:)
          unless path.is_a?(String) && !path.empty? && !path.include?("\0")
            raise ValidationError, "inbox input path differs"
          end
          before = File.lstat(path)
          raise ValidationError, "inbox input is not a bounded regular file" unless before.file? && !before.symlink? && before.size.between?(1, limit)
          snapshot = ->(stat) { [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] }
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |handle|
            raise ValidationError, "inbox input handle changed" unless snapshot.call(before) == snapshot.call(handle.stat)
            bytes = handle.read(before.size + 1)
            unless bytes && bytes.bytesize == before.size && snapshot.call(before) == snapshot.call(handle.stat) &&
                snapshot.call(before) == snapshot.call(File.lstat(path))
              raise ValidationError, "inbox input changed"
            end
            bytes.freeze
          end
        rescue SystemCallError, IOError
          raise ValidationError, "inbox input is unavailable"
        end

        def reverse(path)
          value = InboxContextStore.decode(read(path, limit: 16_384), limit: 16_384)
          InboxDirectEffectBinding.reverse!(value)
        end
      end
    end
  end
end
