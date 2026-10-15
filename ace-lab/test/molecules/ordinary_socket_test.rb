# frozen_string_literal: true

require_relative "../test_helper"
require "socket"
require "json"

module Ace
  module Lab
    class OrdinarySocketTest < Minitest::Test
      HANDSHAKE = Molecules::OrdinarySocket::HANDSHAKE

      def test_submit_delivers_bounded_request_and_returns_framed_response
        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          received = Queue.new
          server = start_server(path) do |socket, _peer|
            header = read_header(socket)
            length = header[/ (\d+)\n/, 1].to_i
            body = socket.read(length)
            received << [header, JSON.parse(body).fetch("request_id")]
            write_frame(socket, {"status" => "ok", "data" => {"schema" => "ace.lab.service.ordinary-merge-ack/v1",
                                                              "type" => "accepted", "request_id" => JSON.parse(body).fetch("request_id"),
                                                              "input_digest" => "e" * 64, "reference" => "fmr1-#{"A" * 40}"}})
          end
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid,
            deadline: Time.now.utc + 10)
          response = client.submit({"request_id" => "request-1"})
          assert_equal "accepted", response.dig("data", "type")
          header, request_id = received.pop
          assert_match(/\A#{Regexp.escape(HANDSHAKE)} \d+\n\z/o, header)
          assert_equal "request-1", request_id
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end
      end

      def test_wrong_receiver_uid_is_an_unavailable_blocker
        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          server = start_server(path) { |_socket, _peer| sleep 0.05 }
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid + 1,
            deadline: Time.now.utc + 5)
          e = assert_raises(Molecules::OrdinarySocket::OrdinaryUnavailable) do
            client.submit({"request_id" => "request-1"})
          end
          assert_includes e.message, "not the installed receiver"
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end
      end

      def test_silent_receiver_hits_the_deadline_as_unavailable
        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          server = start_server(path) { |_socket, _peer| sleep 1 }
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid,
            deadline: Time.now.utc + 0.3)
          assert_raises(Molecules::OrdinarySocket::OrdinaryUnavailable) do
            client.submit({"request_id" => "request-1"})
          end
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end
      end

      def test_garbled_oversized_or_non_json_responses_are_blockers
        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          server = start_server(path) do |socket, _peer|
            read_header(socket)
            socket.read(13)
            socket.write("GARBAGE NOT A FRAME")
          end
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid,
            deadline: Time.now.utc + 5)
          assert_raises(Molecules::OrdinarySocket::OrdinaryUnavailable) do
            client.submit({"request_id" => "request-1"})
          end
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end

        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          server = start_server(path) do |socket, _peer|
            read_header(socket)
            socket.read(13)
            write_frame(socket, "x" * (Molecules::OrdinarySocket::LIMIT + 1))
          end
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid,
            deadline: Time.now.utc + 5)
          assert_raises(Molecules::OrdinarySocket::OrdinaryUnavailable) do
            client.submit({"request_id" => "request-1"})
          end
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end

        Dir.mktmpdir do |dir|
          path = File.join(dir, "ordinary.sock")
          server = start_server(path) do |socket, _peer|
            read_header(socket)
            socket.read(13)
            write_frame(socket, "not json at all")
          end
          client = Molecules::OrdinarySocket.new(socket_path: path, receiver_uid: Process.uid,
            deadline: Time.now.utc + 5)
          assert_raises(Molecules::OrdinarySocket::OrdinaryUnavailable) do
            client.submit({"request_id" => "request-1"})
          end
        ensure
          close_server(server)
          FileUtils.rm_f(path)
        end
      end

      private

      # A controlled in-process receiver: accepts, verifies nothing else, and
      # exercises the framing/identity rules from the receiver side.
      def start_server(path, &handler)
        FileUtils.rm_f(path)
        server = UNIXServer.new(path)
        thread = Thread.new do
          loop do
            socket = server.accept
            begin
              peer = socket.getsockopt(:SOCKET, :PEERCRED).unpack("L3")
              handler.call(socket, peer)
            rescue StandardError, NotImplementedError
              close_quietly(socket)
            end
          end
        rescue IOError, SystemCallError
          nil
        end
        @server_threads = Array(@server_threads).compact.push(thread)
        server
      end

      def close_quietly(socket)
        socket.close
      rescue IOError, SystemCallError
        nil
      end

      def close_server(server)
        return if server.nil?
        server.close
      rescue IOError
        nil
      end

      def read_header(socket)
        header = +""
        until header.end_with?("\n")
          header << socket.read(1)
        end
        header
      end

      def write_frame(socket, document)
        body = document.is_a?(String) ? document : JSON.generate(document)
        socket.write("#{HANDSHAKE} #{body.bytesize}\n#{body}")
      end
    end
  end
end
