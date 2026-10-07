# frozen_string_literal: true
require "json"
require_relative "../../../authority/launch_driver"
module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Launch < Ace::Support::Cli::Command
            desc "Launch one mapped worker and retain its original foreground control channel"
            READY_FIELDS = %w[assignment_id attempt_id generation journal_commit mapping_id original_binding_digest type version].freeze
            READY_LIMIT = 16_384
            option :mapping, required: true, desc: "Installed launch mapping ID"
            option :assignment, desc: "Managed assignment ID"
            option :definition, desc: "Retained final prepared assignment definition JSON file"
            option :prepared_bundle, desc: "Retained original prepared input Git bundle"
            option :step, desc: "Assignment subtree scope"
            option :base_head, desc: "Exact base commit SHA"
            option :mutation, desc: "Stable invocation ID for safe replay"
            option :dry_run, type: :boolean, default: false, desc: "Verify installed boundary without mutation or creation"
            def call(**options)
              driver = build_driver(options.fetch(:mapping))
              result = if options[:dry_run]
                driver.preflight
              else
                %i[assignment definition prepared_bundle step base_head].each do |key|
                  raise ArgumentError, "Missing --#{key.to_s.tr('_', '-')}" unless options[key].is_a?(String) && !options[key].empty?
                end
                definition = retained_input(options[:definition], 32_768).force_encoding(Encoding::UTF_8)
                raise ArgumentError, "assignment definition is not UTF-8" unless definition.valid_encoding?
                bundle = retained_input(options[:prepared_bundle], Ace::Assign::Authority::CandidateTransfer::MAX_BYTES)
                args = {prepared_bundle: bundle, assignment_id: options[:assignment], definition_bytes: definition,
                  scope: options[:step], base_head: options[:base_head]}
                args[:mutation_id] = options[:mutation] if options[:mutation]
                driver.launch(**args)
              end
              if !options[:dry_run] && result["phase"] == "issued"
                retaining_control = true
                announced = false
                driver.serve_control!(state: result) do |ready|
                  raise ArgumentError, "original launch readiness was already announced" if announced
                  line = readiness_line(ready, result, options)
                  $stdout.write(line)
                  $stdout.flush
                  announced = true
                end
                raise ArgumentError, "original control ended before authenticated readiness" unless announced
              else
                puts JSON.generate(result)
              end
            rescue ArgumentError, SystemCallError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            ensure
              # Local foreground-loop cancellation is not a stopped/settled proof.
              driver.request_control_cancel if retaining_control
            end
            private
            def retained_input(path, limit)
              File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
                before = file.stat
                unless before.file? && before.size.between?(1, limit)
                  raise ArgumentError, "retained launch input is not a bounded regular file"
                end
                bytes = (file.read(limit + 1) || "").b
                after = file.stat
                identity = ->(stat) { [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] }
                unless bytes.bytesize == before.size && bytes.bytesize <= limit && identity.call(before) == identity.call(after)
                  raise ArgumentError, "retained launch input changed while reading"
                end
                bytes
              end
            end

            def readiness_line(ready, result, options)
              unless ready.is_a?(Hash) && ready.keys.all? { |key| key.is_a?(String) } && ready.keys.sort == READY_FIELDS &&
                  ready["version"].is_a?(Integer) && ready["version"] == 1 && ready["type"] == "launch_ready" &&
                  ready.values_at("mapping_id", "assignment_id", "attempt_id") ==
                    [options.fetch(:mapping), options.fetch(:assignment), result.fetch("attempt_id")] &&
                  ready["generation"].is_a?(Integer) && ready["generation"].positive? &&
                  ready["journal_commit"].is_a?(String) && ready["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
                  ready["original_binding_digest"].is_a?(String) && ready["original_binding_digest"].match?(/\A[0-9a-f]{64}\z/)
                raise ArgumentError, "original launch readiness is malformed or mismatched"
              end
              line = JSON.generate(ready) + "\n"
              raise ArgumentError, "original launch readiness is oversized" if line.bytesize > READY_LIMIT
              line
            end

            def build_driver(mapping)
              Ace::Assign::Authority::LaunchDriver.new(mapping_id: mapping)
            end
          end
        end
      end
    end
  end
end
