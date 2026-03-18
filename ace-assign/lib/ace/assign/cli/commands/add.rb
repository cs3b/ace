# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Add a new step dynamically
        #
        # Supports hierarchical step injection:
        # - Default: adds after current/last done step
        # - --after: adds as sibling after specified step
        # - --after + --child: adds as child of specified step
        #
        # @example Add step after current
        #   ace-assign add fix-tests -i "Fix the failing tests"
        #
        # @example Inject sibling after specific step
        #   ace-assign add verify --after 010 -i "Verify initialization"
        #   # Creates 011-verify.st.md (renumbers existing 011+ if needed)
        #
        # @example Inject child step
        #   ace-assign add verify --after 010 --child -i "Verify"
        #   # Creates 010.01-verify.st.md
        class Add < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Add a new step to the queue dynamically"

          argument :name, required: true, desc: "Step name"
          option :instructions, aliases: ["-i"], desc: "Step instructions"
          option :after, aliases: ["-a"], desc: "Insert after this step number (e.g., 010)"
          option :child, aliases: ["-c"], type: :boolean, default: false, desc: "Insert as child of --after step"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(name:, **options)
            # Validate: --child requires --after
            if options[:child] && !options[:after]
              raise Ace::Support::Cli::Error, "--child requires --after to specify the parent step"
            end

            # Validate: adding child would not exceed MAX_DEPTH
            if options[:child] && options[:after]
              parsed = Atoms::StepNumbering.parse(options[:after])
              max_depth = Atoms::StepNumbering::MAX_DEPTH
              if parsed[:depth] >= max_depth
                raise Ace::Support::Cli::Error,
                      "Cannot add child: would exceed maximum nesting depth of #{max_depth + 1} levels " \
                      "(parent '#{options[:after]}' is at depth #{parsed[:depth]})"
              end
            end

            instructions = options[:instructions] || "Complete this step and finish with: ace-assign finish --message report.md"

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
              puts "Created: steps/#{File.basename(added.file_path)}"
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
                puts "Renumbered steps:"
                result[:renumbered].each do |old_num|
                  new_num = Atoms::StepNumbering.shift_number(old_num, 1)
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
