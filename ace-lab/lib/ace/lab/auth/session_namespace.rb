# frozen_string_literal: true

require "fiddle"

module Ace
  module Lab
    module Auth
      # A descriptor pins the authenticated main process's mount namespace;
      # it is never selected by the socket request. Only system-owned private
      # namespaces are eligible for a root issuer to enter.
      module SessionNamespace
        NS_GET_USERNS = 0xb701
        NS_GET_NSTYPE = 0xb703
        CLONE_NEWNS = 0x0002_0000
        CLONE_FS = 0x0000_0200
        module_function

        def capture(pid, proc_root: "/proc")
          raise ArgumentError, "mount namespace requires Linux" unless RUBY_PLATFORM.include?("linux")
          raise ArgumentError, "invalid session process" unless pid.is_a?(Integer) && pid.positive?

          namespace = File.open(File.join(proc_root, pid.to_s, "ns/mnt"), File::RDONLY)
          namespace.close_on_exec = true
          raise ArgumentError, "session namespace is not a mount namespace" unless namespace.ioctl(NS_GET_NSTYPE, 0) == CLONE_NEWNS

          owner = IO.for_fd(namespace.ioctl(NS_GET_USERNS, 0), autoclose: true)
          owner.close_on_exec = true
          initial_user = File.stat(File.join(proc_root, "1/ns/user"))
          initial_mount = File.stat(File.join(proc_root, "1/ns/mnt"))
          unless same?(owner.stat, initial_user) && !same?(namespace.stat, initial_mount) && matches?(namespace, pid, proc_root: proc_root)
            raise ArgumentError, "session mount namespace is not a private system namespace"
          end
          namespace
        rescue Exception
          namespace&.close unless namespace&.closed?
          raise
        ensure
          owner&.close unless owner&.closed?
        end

        def matches?(namespace, pid, proc_root: "/proc")
          namespace.is_a?(IO) && !namespace.closed? && pid.is_a?(Integer) && pid.positive? &&
            same?(namespace.stat, File.stat(File.join(proc_root, pid.to_s, "ns/mnt")))
        rescue SystemCallError, IOError
          false
        end

        def enter!(namespace)
          raise ArgumentError, "mount namespace is unavailable" unless namespace.is_a?(IO) && !namespace.closed?
          # A Ruby child may still share filesystem attributes after fork;
          # Linux refuses setns in that state and a later chdir must not
          # change the issuer's filesystem context.
          unshare = Fiddle::Function.new(Fiddle::Handle::DEFAULT["unshare"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          raise ArgumentError, "cannot isolate filesystem attributes" unless unshare.call(CLONE_FS).zero?
          fn = Fiddle::Function.new(Fiddle::Handle::DEFAULT["setns"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          raise ArgumentError, "cannot enter session mount namespace" unless fn.call(namespace.fileno, CLONE_NEWNS).zero?
        rescue Fiddle::DLError
          raise ArgumentError, "cannot enter session mount namespace"
        end

        def same?(left, right) = [left.dev, left.ino] == [right.dev, right.ino]
        private_class_method :same?
      end
    end
  end
end
