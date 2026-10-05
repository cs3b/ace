# frozen_string_literal: true

require "json"
require "open3"
require "timeout"
require "ace/assign/authority/private_directory"

module Ace
  module Lab
    module Molecules
      # Source-owned receiver handler. Permission admission is a separate
      # authority operation; this runner never grants or reconstructs it.
      class ProtectedServiceHandler
        MAX_STDOUT = 16 * 1024
        MAX_STDERR = 8 * 1024

        def execute(operation:, envelope:, candidate_root:)
          unless Process.uid == operation.fetch("executor_uid") && Process.euid == operation.fetch("executor_uid")
            raise SecurityError, "handler executor differs"
          end
          root = Ace::Assign::Authority::PrivateDirectory.verify!(candidate_root)
          out = nil
          Open3.popen3({"PATH" => "/usr/bin:/bin", "LANG" => "C.UTF-8", "HOME" => root},
            *operation.fetch("argv"), chdir: root, pgroup: true, unsetenv_others: true) do |stdin, stdout, stderr, waiter|
            readers = []
            begin
              Timeout.timeout(30) do
                readers = [Thread.new { bounded(stdout, MAX_STDOUT) }, Thread.new { bounded(stderr, MAX_STDERR) }]
                stdin.write(JSON.generate(envelope))
                stdin.close
                output, errors = readers.map(&:value)
                unless output && errors && waiter.value.success?
                  return nil
                end
                out = output
              end
            rescue Timeout::Error, IOError, SystemCallError
              return nil
            ensure
              stdin.close unless stdin.closed?
              # This group is created and owned by this receiver. Termination
              # is cleanup, never proof that an arbitrary handler left no effect.
              Process.kill("KILL", -waiter.pid) rescue nil
              waiter.value
              [stdout, stderr].each { |io| io.close unless io.closed? }
              readers.each(&:join)
            end
          end
          response = JSON.parse(out)
          request = envelope.fetch("request")
          unless response.is_a?(Hash) && response.keys.sort == %w[evidence input_digest outcome request_id] &&
              response["request_id"] == request.fetch("request_id") && response["input_digest"] == request.fetch("input_digest") &&
              %w[succeeded failed].include?(response["outcome"]) && response["evidence"].is_a?(Array)
            return nil
          end
          response
        rescue JSON::ParserError
          nil
        end

        private

        def bounded(io, limit)
          bytes = io.read(limit + 1).to_s
          bytes.bytesize <= limit ? bytes : nil
        rescue IOError, SystemCallError
          nil
        ensure
          io.close unless io.closed?
        end
      end
    end
  end
end
