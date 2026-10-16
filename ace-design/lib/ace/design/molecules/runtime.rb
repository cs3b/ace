# frozen_string_literal: true
require "open3"
require "ace/core/atoms/process_terminator"
module Ace
  module Design
    module Molecules
      class Runtime
        attr_reader :node, :directory
        def initialize(config = Design.config)
          @node = config.fetch("node")
          @directory = File.expand_path(config.fetch("runtime_dir"))
        end
        def script(name)
          File.join(Design.gem_root, "browser", name)
        end
        def capture(*argv, timeout:)
          output = [String.new, String.new]
          status = nil
          Open3.popen3(*argv, pgroup: true) do |stdin, stdout, stderr, waiter|
            stdin.close
            readers = [stdout, stderr].each_with_index.map do |stream, i|
              Thread.new do
                loop do
                  chunk = stream.readpartial(16_384)
                  remaining = 262_144 - output[i].bytesize
                  output[i] << chunk.byteslice(0, remaining) if remaining.positive?
                end
              rescue EOFError, IOError
                nil
              end
            end
            begin
              unless waiter.join(timeout)
                raise Error, "Command #{argv.first.inspect} timed out after #{timeout}s"
              end
              status = waiter.value
            ensure
              # A completed command can leave descendants holding its pipes. Their
              # lifetime belongs to this capture, not to the caller's next command.
              Thread.handle_interrupt(Interrupt => :never) do
                Ace::Core::Atoms::ProcessTerminator.terminate(-waiter.pid)
                deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 1
                readers.each do |reader|
                  remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                  reader.join([remaining, 0].max)
                end
                [stdout, stderr].each { |io| io.close unless io.closed? }
                readers.each { |reader| reader.kill if reader.alive? }
                readers.each { |reader| reader.join(0.1) }
              end
            end
          end
          {"stdout" => output[0], "stderr" => output[1], "exit_code" => status.exitstatus}
        rescue Errno::ENOENT
          raise Error, "Command executable unavailable: #{argv.first}"
        end
        def doctor
          result = capture(node, script("doctor.mjs"), directory, timeout: 15)
          data = JSON.parse(result["stdout"])
          data["runtime_dir"] = directory
          data["manifest_dir"] = File.join(Design.gem_root, "browser")
          data
        rescue Error, JSON::ParserError => e
          {"ready" => false, "error" => e.message, "runtime_dir" => directory,
           "manifest_dir" => File.join(Design.gem_root, "browser")}
        end
        def preview(session, port: 0)
          Kernel.exec(node, script("preview.mjs"), session.root, port.to_s)
        rescue Errno::ENOENT
          raise Error, "Preview requires Node 22+; configured executable: #{node}"
        end
      end
    end
  end
end
