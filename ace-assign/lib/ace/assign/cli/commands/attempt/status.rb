# frozen_string_literal: true

require "json"
require_relative "base"

module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          # Show attempt state, binding facts, and evidence references.
          # JSON output carries only state, binding, references, and digests
          # — never credentials or receipt bytes.
          class Status < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Attempt::Base

            desc "Show attempt status for an assignment"

            option :assignment, desc: "Assignment ID"
            option :format, desc: "Output format (json, text)", default: "json"

            def call(**options)
              assignment = require_option(options, :assignment, "status --assignment ID --format json")
              projection = build_coordinator.status(assignment)

              if options[:format] == "text"
                print_text(assignment, projection)
              else
                emit_json(projection || {"attempt" => nil})
              end
            end

            private

            def print_text(assignment, projection)
              return puts "No attempts recorded for #{assignment}" if projection.nil?

              puts "Attempt: #{projection['attempt_id']} #{projection['state']} (#{projection['scope']})"
              puts "Recovery: #{projection['recovery_mode']}"
              puts "Base head: #{projection['base_head']}"
              puts "Candidate head: #{projection['candidate_head'] || 'unpinned'}"
              puts "Evidence ref: #{projection['evidence_git_ref'] || 'local-only'}"
              puts "Journal commit: #{projection['journal_commit'] || 'none'}"
              return unless projection["unresolved_effects"].any?

              puts "Unresolved effects: #{projection['unresolved_effects'].join(', ')}"
            end
          end
        end
      end
    end
  end
end
