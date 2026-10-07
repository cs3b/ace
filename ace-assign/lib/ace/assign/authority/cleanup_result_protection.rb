# frozen_string_literal: true

require "fiddle"
require "ace/runtime/molecules/protected_artifact_set"

module Ace
  module Assign
    module Authority
      # Extends the existing held artifact protection solely for the bounded
      # root result view. Private archive storage is never admitted here.
      class CleanupResultProtection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
        class LinuxACL
          def absent!(handle, attribute)
            unless RUBY_PLATFORM.include?("linux")
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup result ACL evidence requires Linux"
            end
            function = Fiddle::Function.new(Fiddle::Handle::DEFAULT["fgetxattr"],
              [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SSIZE_T)
            size = function.call(handle.fileno, attribute, 0, 0)
            error = Fiddle.last_error
            unless size == -1 && error == Errno::ENODATA::Errno
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup result ACL protection is unavailable"
            end
          rescue Fiddle::DLError
            raise Ace::Runtime::RuntimeUnavailableError, "cleanup result ACL reader is unavailable"
          end
        end

        def initialize(result_path:, authority_gid:, acl: LinuxACL.new, **options)
          unless result_path.is_a?(String) && result_path.start_with?("/") && !result_path.include?("\0") &&
              File.expand_path(result_path) == result_path && authority_gid.is_a?(Integer) && authority_gid.positive?
            raise ArgumentError, "invalid fixed cleanup result view"
          end
          super(**options)
          @result_path, @parent, @authority_gid, @acl = result_path.dup.freeze, File.dirname(result_path).freeze, authority_gid, acl
        end

        def verify!(path, handle, directory:)
          super
          return unless path == @result_path || path == @parent
          parent = path == @parent
          stat = handle.stat
          unless directory == parent && stat.gid == @authority_gid &&
              (stat.mode & 0o7777) == (parent ? 0o2750 : 0o640)
            raise Ace::Runtime::RuntimeUnavailableError, "cleanup result view mode or group differs"
          end
          @acl.absent!(handle, "system.posix_acl_access")
          @acl.absent!(handle, "system.posix_acl_default") if parent
        end
      end
    end
  end
end
