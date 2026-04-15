# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Verify < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Verify an existing asciinema cast against a YAML demo tape"

          argument :cast, required: true, desc: "Cast file path"

          option :tape, type: :string, required: true, desc: "Tape preset name or .tape.yml path"
          option :sandbox_path, type: :string, desc: "Optional sandbox path for assertion replay"
          option :report_dir, type: :string, desc: "Directory for non-pass verification reports"

          def call(cast:, tape:, **options)
            resolved_tape = Molecules::TapeResolver.new.resolve(tape)
            unless resolved_tape.end_with?(".tape.yml", ".tape.yaml")
              raise Ace::Support::Cli::Error, "ace-demo verify requires a .tape.yml tape"
            end

            spec = Atoms::DemoYamlParser.parse_file(resolved_tape)
            verification = Molecules::CastVerifier.new.verify(
              cast_path: File.expand_path(cast),
              tape_spec: spec,
              sandbox_path: options[:sandbox_path],
              env: {}
            )

            print_verification(verification)
            return if verification.success?

            report_path = Molecules::VerificationReportWriter.new(
              base_dir: options[:report_dir] || File.join(Dir.pwd, ".ace-local/demo")
            ).write(
              demo_name: File.basename(cast, File.extname(cast)),
              verification: verification
            )
            puts "Verification report: #{report_path}"
            raise Ace::Support::Cli::Error, "Demo verification failed (#{verification.classification}). Report: #{report_path}"
          rescue TapeNotFoundError, DemoYamlParseError, CastParseError, ArgumentError => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def print_verification(verification)
            puts "Verification: #{verification.status}"
            puts "Classification: #{verification.classification}" if verification.classification
            puts "Summary: #{verification.summary}" if verification.summary
            missing = verification.commands_missing
            puts "Missing commands: #{missing.join(', ')}" unless missing.empty?
            missing_vars = verification.details&.fetch(:missing_vars, [])
            puts "Missing vars: #{missing_vars.join(', ')}" unless missing_vars.empty?
            missing_output = verification.details&.fetch(:missing_output, [])
            puts "Missing output: #{missing_output.join(', ')}" unless missing_output.empty?
            missing_sequence = verification.details&.fetch(:missing_output_sequence, [])
            puts "Missing output sequence: #{missing_sequence.join(' -> ')}" unless missing_sequence.empty?
            puts "Assertions replay: skipped" if verification.details&.fetch(:assertions_skipped, false)
          end
        end
      end
    end
  end
end
