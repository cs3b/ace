# frozen_string_literal: true
require "fiddle"

module Ace
  module Assign
    module Authority
      # Linux POSIX access ACL evaluation for a fixed unprivileged principal.
      # No credential switching; unsupported or unreadable policy refuses admission.
      class PosixAcl
        def entries(path, attribute: "system.posix_acl_access")
          unless %w[system.posix_acl_access system.posix_acl_default].include?(attribute)
            raise ArgumentError, "unsupported POSIX ACL attribute"
          end
          raise Ace::Runtime::RuntimeUnavailableError, "receiver ACL inspection requires Linux" unless RUBY_PLATFORM.include?("linux")
          function = Fiddle::Function.new(Fiddle::Handle::DEFAULT["lgetxattr"],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SSIZE_T)
          buffer = Fiddle::Pointer.malloc(8192, Fiddle::RUBY_FREE)
          count = function.call(path, attribute, buffer, 8192)
          return nil if count == -1 && Fiddle.last_error == Errno::ENODATA::Errno
          raise Ace::Runtime::RuntimeUnavailableError, "receiver access ACL is unreadable" if count < 4 || (count - 4) % 8 != 0
          bytes = buffer[0, count]
          raise Ace::Runtime::RuntimeUnavailableError, "unknown receiver ACL version" unless bytes.unpack1("L<") == 2
          rows = bytes.byteslice(4..).unpack("S<S<L<" * ((count - 4) / 8)).each_slice(3).to_a
          validate!(rows)
          rows
        rescue Fiddle::DLError
          raise Ace::Runtime::RuntimeUnavailableError, "receiver ACL inspection is unavailable"
        end

        def searchable?(path, stat:, uid:, groups:)
          rows = entries(path)
          unless rows
            shift = uid == stat.uid ? 6 : (groups.include?(stat.gid) ? 3 : 0)
            return ((stat.mode >> shift) & 1) == 1
          end
          return (rows.find { |tag, _perm, _id| tag == 1 }[1] & 1) == 1 if uid == stat.uid
          mask = rows.find { |tag, _perm, _id| tag == 16 }&.at(1) || 7
          named = rows.find { |tag, _perm, id| tag == 2 && id == uid }
          return (named[1] & mask & 1) == 1 if named
          matched = rows.select { |tag, _perm, id| (tag == 4 && groups.include?(stat.gid)) || (tag == 8 && groups.include?(id)) }
          return matched.any? { |_tag, perm, _id| (perm & mask & 1) == 1 } unless matched.empty?
          (rows.find { |tag, _perm, _id| tag == 32 }[1] & 1) == 1
        end

        private

        def validate!(rows)
          valid = rows.all? { |tag, perm, id| [1, 2, 4, 8, 16, 32].include?(tag) && (0..7).cover?(perm) &&
            ([2, 8].include?(tag) ? id != 0xffffffff : id == 0xffffffff) }
          valid &&= [1, 4, 32].all? { |tag| rows.count { |row| row[0] == tag } == 1 }
          valid &&= rows.count { |row| row[0] == 16 } <= 1
          valid &&= [2, 8].all? { |tag| ids = rows.select { |row| row[0] == tag }.map(&:last); ids.uniq == ids }
          valid &&= !rows.any? { |row| [2, 8].include?(row[0]) } || rows.count { |row| row[0] == 16 } == 1
          raise Ace::Runtime::RuntimeUnavailableError, "invalid receiver access ACL" unless valid
        end
      end
    end
  end
end
