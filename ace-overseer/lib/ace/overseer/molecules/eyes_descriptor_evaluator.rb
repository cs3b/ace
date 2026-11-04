# frozen_string_literal: true
require "fcntl"
require_relative "eyes_session_evidence"
require_relative "../atoms/start_contract"
require_relative "../atoms/observation_sources"

module Ace
  module Overseer
    module Molecules
      # Installed owner-side evaluator. The issuer supplies one authenticated
      # read-only file descriptor; it never supplies alternative evidence rules.
      class EyesDescriptorEvaluator
        FIELDS = %w[pane terminal_id root session_path process role].freeze

        def initialize(executor: nil, identity: EyesSessionEvidence::LinuxIdentity.new, clock: -> { (Time.now.to_f * 1000).to_i })
          @executor, @identity, @clock = executor, identity, clock
        end

        def call(input, file:)
          return false unless input.is_a?(Hash) && input.keys.sort == FIELDS.sort &&
            %w[lab-overseer project-overseer].include?(input["role"]) &&
            %w[pane terminal_id root session_path].all? { |key| input[key].is_a?(String) &&
              input[key].bytesize.between?(1, 4096) && !input[key].match?(/[[:cntrl:]]/) } &&
            file.is_a?(File) && !file.closed? && file.stat.file? &&
            (file.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE) == Fcntl::O_RDONLY
          expected = input["process"]
          return false unless expected.is_a?(Hash) && expected.keys.sort == %w[pid started_at uid] &&
            expected["pid"].is_a?(Integer) && expected["pid"].positive? && expected["uid"].is_a?(Integer) &&
            expected["started_at"].is_a?(String) && @identity.capture(expected["pid"]) == expected
          bound_identity = Object.new
          source = @identity
          bound_identity.define_singleton_method(:capture) do |pid|
            value = source.capture(pid)
            value if pid == expected["pid"] && value == expected
          end
          opener = lambda do |path|
            raise IOError, "session descriptor binding differs" unless path == input["session_path"]
            file.dup.tap(&:rewind)
          end
          required = Atoms::ObservationSources::REQUIRED.dup
          required << Atoms::ObservationSources::PROJECT_SESSIONS if input["role"] == "lab-overseer"
          EyesSessionEvidence.new(executor: @executor, identity: bound_identity, clock: @clock, file_opener: opener)
            .ready?(pane: input["pane"], root: input["root"], prompt: Atoms::StartContract::FIRST_TURN_PROMPT,
              required_sources: required, expected_terminal: input["terminal_id"])
        rescue SystemCallError, IOError, ArgumentError, TypeError
          false
        end
      end
    end
  end
end
