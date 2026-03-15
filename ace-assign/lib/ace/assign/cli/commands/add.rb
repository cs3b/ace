# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Add a new phase dynamically
        #
        # Supports hierarchical phase injection:
        # - Default: adds after current/last done phase
        # - --after: adds as sibling after specified phase
        # - --after + --child: adds as child of specified phase
        #
        # @example Add phase after current
        #   ace-assign add fix-tests -i "Fix the failing tests"
        #
        # @example Inject sibling after specific phase
        #   ace-assign add verify --after 010 -i "Verify initialization"
        #   # Creates 011-verify.ph.md (renumbers existing 011+ if needed)
        #
        # @example Inject child phase
        #   ace-assign add verify --after 010 --child -i "Verify"
        #   # Creates 010.01-verify.ph.md
        class Add < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base
          include AssignmentTarget

          desc "Add a new phase to the queue dynamically"

          argument :name, required: true, desc: "Phase name"
          option :instructions, aliases: ["-i"], desc: "Phase instructions"
          option :after, aliases: ["-a"], desc: "Insert after this phase number (e.g., 010)"
          option :child, aliases: ["-c"], type: :boolean, default: false, desc: "Insert as child of --after phase"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(name:, **options)
            # Validate: --child requires --after
            if options[:child] && !options[:after]
              raise Ace::Core::CLI::Error, "--child requires --after to specify the parent phase"
            end

            # Validate: adding child would not exceed MAX_DEPTH
            if options[:child] && options[:after]
              parsed = Atoms::PhaseNumbering.parse(options[:after])
              max_depth = Atoms::PhaseNumbering::MAX_DEPTH
              if parsed[:depth] >= max_depth
                raise Ace::Core::CLI::Error,
                      "Cannot add child: would exceed maximum nesting depth of #{max_depth + 1} levels " \
                      "(parent '#{options[:after]}' is at depth #{parsed[:depth]})"
              end
            end

            instructions = options[:instructions] || "Complete this phase and finish with: ace-assign finish --message report.md"

            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.add(
              name,
              instructions,
              after: options[:after],
              as_child: options[:child]
            )

            unless options[:quiet]
              added = result[:added]
              puts "Created: phases/#{File.basename(added.file_path)}"
              puts "Number: #{added.number}"
              puts "Status: #{added.status}"

              if options[:after]
                if options[:child]
                  puts "Relationship: child of #{options[:after]}"
                else
                  puts "Relationship: sibling after #{options[:after]}"
                end
              end

              if result[:renumbered]&.any?
                puts
                puts "Renumbered phases:"
                result[:renumbered].each do |old_num|
                  new_num = Atoms::PhaseNumbering.shift_number(old_num, 1)
                  puts "  #{old_num} -> #{new_num}"
                end
              end

              if added.status == :in_progress
                puts
                puts "Instructions:"
                puts added.instructions
              end
            end
          end

          private
        end
      end
    end
  end
end
