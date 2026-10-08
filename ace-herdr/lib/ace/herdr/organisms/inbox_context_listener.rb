# frozen_string_literal: true

require "socket"
require_relative "inbox_context_server"
require_relative "../molecules/inbox_context_service_configuration"

module Ace
  module Herdr
    module Organisms
      # Connection lifetimes never retire admission metadata. Stop prevents
      # new ingress, then waits within one deadline for existing handlers.
      class InboxContextListener
        MAX_HANDLERS = 8
        STOP_SECONDS = 35

        def initialize(configuration:, server:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          protection: Ace::Runtime::Molecules::ProtectedSocket, handler_dispatcher: nil)
          unless configuration.is_a?(Molecules::InboxContextServiceConfiguration)
            raise ValidationError, "context listener configuration is not held"
          end
          @configuration, @server, @kernel, @protection = configuration, server, kernel, protection
          @handler_dispatcher = handler_dispatcher
          @path = configuration.data.fetch("control_socket_path")
          @credentials = configuration.data.fetch("owner_credentials")
          @mutex, @handlers, @stopping = Mutex.new, {}, false
        end

        def serve
          me = @kernel.capture(Process.pid)
          unless me.values_at("uid", "gid", "groups") == @credentials.values_at("uid", "gid", "groups")
            raise ValidationError, "context listener principal differs"
          end
          @kernel.live!(me)
          @protection.root_path!(File.dirname(@path), directory: true, owner: @credentials.fetch("uid"))
          verify_socket_traversal!
          @lock = File.open("#{@path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW | File::NONBLOCK, 0o600)
          stat = @lock.stat
          unless stat.file? && stat.uid == @credentials.fetch("uid") && stat.nlink == 1 && (stat.mode & 0o7777) == 0o600 &&
              [stat.dev, stat.ino] == File.lstat("#{@path}.lock").then { |current| [current.dev, current.ino] } &&
              @lock.flock(File::LOCK_EX | File::LOCK_NB)
            raise ValidationError, "context listener lease differs or is held"
          end
          @lock.close_on_exec = true
          remove_stale_endpoint!
          @listener = UNIXServer.new(@path)
          File.chown(nil, @configuration.data.fetch("socket_gid"), @path)
          File.chmod(0o660, @path)
          @identity = @protection.socket_identity(@path)
          until stopping?
            socket = @listener.accept
            accepted_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 60
            @mutex.synchronize do
              if @stopping || @handlers.size >= MAX_HANDLERS
                socket.close
              else
                gate = Queue.new
                thread = Thread.new(socket, accepted_deadline) do |connection, operation_deadline|
                  gate.pop
                  begin
                    if @handler_dispatcher
                      @handler_dispatcher.call(deadline: operation_deadline) { @server.handle(connection) }
                    else
                      @server.handle(connection)
                    end
                  rescue ValidationError, Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError, Timeout::Error
                    # Wire loss preserves the owner's retained operation state.
                    nil
                  ensure
                    connection.close
                    @mutex.synchronize { @handlers.delete(Thread.current) }
                  end
                end
                @handlers[thread] = socket
                gate << true
              end
            end
          end
        rescue IOError, Errno::EBADF
          raise unless stopping?
        ensure
          stop if @listener
          @listener&.close
          remove_owned_endpoint!
          @lock&.close
        end

        def stop(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + STOP_SECONDS)
          unless deadline.is_a?(Numeric) && deadline.finite?
            raise ValidationError, "context stop deadline differs"
          end
          threads = @mutex.synchronize do
            @stop_deadline = @stop_deadline ? [@stop_deadline, deadline].min : deadline
            @stopping = true
            @listener&.close
            @handlers.keys
          end
          threads.each do |thread|
            remaining = @stop_deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            break unless remaining.positive?
            thread.join(remaining)
          end
          if @mutex.synchronize { !@handlers.empty? }
            raise ValidationError, "context handlers remain unresolved at stop deadline"
          end
          true
        end

        def quiescent?
          @mutex.synchronize { @handlers.empty? && (!@listener || @listener.closed?) }
        end

        private

        def stopping? = @mutex.synchronize { @stopping }

        def verify_socket_traversal!
          parent = File.dirname(@path)
          stat = File.lstat(parent)
          unless stat.gid == @configuration.data.fetch("socket_gid") && (stat.mode & 0o7777) == 0o750
            raise ValidationError, "context socket parent is not the exact shared traversal directory"
          end
          loop do
            stat = File.lstat(parent)
            unless stat.directory? && !stat.symlink? && @configuration.data.fetch("grants").all? { |grant|
              bit = stat.uid == grant.fetch("uid") ? 0o100 : (grant.fetch("groups") + [grant.fetch("gid")]).include?(stat.gid) ? 0o010 : 0o001
              grant.fetch("uid").zero? || (stat.mode & bit).positive?
            }
              raise ValidationError, "context caller cannot traverse its fixed socket ancestry"
            end
            break if parent == "/"
            parent = File.dirname(parent)
          end
        end

        def remove_stale_endpoint!
          stat = File.lstat(@path)
          raise ValidationError, "context endpoint differs" unless stat.socket? && stat.uid == @credentials.fetch("uid")
          File.unlink(@path)
        rescue Errno::ENOENT
          nil
        end

        def remove_owned_endpoint!
          File.unlink(@path) if @identity && @protection.socket_identity(@path) == @identity
        rescue Errno::ENOENT
          nil
        end
      end
    end
  end
end
