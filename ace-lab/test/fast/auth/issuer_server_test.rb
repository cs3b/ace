# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_server"
require "timeout"

module Ace
  module Lab
    module Auth
      class IssuerServerTest < Minitest::Test
        def with_server(handler)
          Dir.mktmpdir do |dir|
            path = File.join(dir, "issuer.sock")
            listener = Socket.new(:UNIX, :STREAM)
            listener.bind(Socket.sockaddr_un(path))
            listener.listen(8)
            pid = fork do
              IssuerServer.new(handler: handler, max_supervisions: 2).run(listener, invocation: "a" * 32)
              exit! 0
            rescue Error
              exit! 1
            end
            listener.close
            yield path, pid
          ensure
            begin
              Process.kill("TERM", pid) if pid
            rescue Errno::ESRCH
              nil
            end
            begin
              Process.waitpid(pid) if pid
            rescue Errno::ECHILD
              nil
            end
          end
        end

        def test_two_connections_share_invocation_and_do_not_block_each_other
          handler = Object.new
          handler.define_singleton_method(:call) do |socket, invocation:, **|
            socket.puts invocation
            socket.gets
            socket.close
            :consumed
          end
          with_server(handler) do |path, _pid|
            first = UNIXSocket.new(path)
            second = UNIXSocket.new(path)
            Timeout.timeout(3) do
              assert_equal "a" * 32 + "\n", first.gets
              assert_equal "a" * 32 + "\n", second.gets
            end
          ensure
            [first, second].compact.each(&:close)
          end
        end

        def test_handler_cleanup_failure_stops_admission
          handler = Object.new
          handler.define_singleton_method(:call) do |socket, invocation:, **|
            socket.close
            :cleanup_failed
          end
          with_server(handler) do |path, pid|
            UNIXSocket.new(path).close
            _, status = Timeout.timeout(3) { Process.waitpid2(pid) }
            assert_equal 1, status.exitstatus
          end
        end

        def test_full_lease_capacity_keeps_status_connections_available
          handler = Object.new
          handler.define_singleton_method(:call) do |socket, invocation:, allow_request:, supervising:|
            if socket.gets == "request\n"
              if allow_request
                supervising.call
                socket.puts "issued"
                socket.gets
              else
                socket.puts "capacity"
              end
            else
              socket.puts "status"
            end
            socket.close
            :completed
          end
          with_server(handler) do |path, _pid|
            clients = []
            Timeout.timeout(3) do
              2.times do
                clients << UNIXSocket.new(path)
                clients.last.puts "request"
                assert_equal "issued\n", clients.last.gets
              end
              clients << UNIXSocket.new(path)
              clients.last.puts "request"
              assert_equal "capacity\n", clients.last.gets
              clients << UNIXSocket.new(path)
              clients.last.puts "status"
              assert_equal "status\n", clients.last.gets
            end
          ensure
            clients&.each(&:close)
          end
        end
      end
    end
  end
end
