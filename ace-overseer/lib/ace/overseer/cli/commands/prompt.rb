# frozen_string_literal: true
require "json"
require_relative "../../organisms/protected_steering"
module Ace
  module Overseer
    module CLI
      module Commands
        class Prompt < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Prompt an exact protected attempt or inspect its original prompt mutation"
          option :project, required: true, desc: "Installed project ID"
          option :agent, required: true, desc: "Literal installed mapping ID"
          option :assignment, required: true, desc: "Original assignment ID"
          option :attempt, required: true, desc: "Original attempt ID"
          option :mutation, required: true, desc: "Stable original prompt mutation ID"
          option :expected_generation, type: :integer, desc: "Observed original generation; never refreshed"
          option :file, desc: "Read exact bounded prompt bytes from this regular file"
          option :stdin, type: :boolean, default: false, desc: "Read exact bounded prompt bytes from redirected stdin"
          option :status, type: :boolean, default: false, desc: "Read original prompt status without sending input"
          def initialize(steering: nil, input: $stdin)
            super()
            @steering = steering || Organisms::ProtectedSteering.new
            @input = input
          end
          def call(project:, agent:, assignment:, attempt:, mutation:, expected_generation: nil,
            file: nil, stdin: false, status: false, **extra)
            raise Error, "Unsupported prompt options" unless extra.empty?
            text = if status
              raise Error, "Prompt status forbids input selectors and expected generation" if file || stdin || expected_generation
              nil
            else
              raise Error, "Select exactly one --file or --stdin" unless (!!file ^ !!stdin)
              file ? file_bytes(file) : stdin_bytes
            end
            result = @steering.prompt(project: project, agent: agent, assignment: assignment, attempt: attempt,
              mutation: mutation, expected_generation: expected_generation, text: text, status: status)
            puts JSON.pretty_generate(result)
          rescue StandardError => error
            raise Ace::Support::Cli::Error, error.message
          end
          private
          def stdin_bytes
            raise Error, "--stdin requires redirected input" if @input.respond_to?(:tty?) && @input.tty?
            @input.read(16_385) || ""
          end
          def file_bytes(path)
            File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
              before = file.stat
              raise Error, "Prompt file must be bounded and regular" unless before.file? && before.size.between?(1, 16_384)
              bytes = file.read(16_385) || ""
              after = file.stat
              identity = ->(stat) { [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] }
              unless bytes.bytesize == before.size && identity.call(before) == identity.call(after)
                raise Error, "Prompt file changed during held read"
              end
              bytes
            end
          end
        end
      end
    end
  end
end
