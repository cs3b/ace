# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Add a new step dynamically
        #
        # Supports hierarchical job injection:
        # - Default: adds after current/last done step
        # - --after: adds as sibling after specified job
        # - --after + --child: adds as child of specified job
        #
        # @example Add step after current
        #   ace-coworker add fix-tests -i "Fix the failing tests"
        #
        # @example Inject sibling after specific job
        #   ace-coworker add verify --after 010 -i "Verify initialization"
        #   # Creates 011-verify.j.md (renumbers existing 011+ if needed)
        #
        # @example Inject child job
        #   ace-coworker add verify --after 010 --child -i "Verify"
        #   # Creates 010.01-verify.j.md
        class Add < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Add a new step to the queue dynamically"

          argument :name, required: true, desc: "Step name"
          option :instructions, aliases: ["-i"], desc: "Step instructions"
          option :after, aliases: ["-a"], desc: "Insert after this job number (e.g., 010)"
          option :child, aliases: ["-c"], type: :boolean, default: false, desc: "Insert as child of --after job"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(name:, **options)
            # Validate: --child requires --after
            if options[:child] && !options[:after]
              raise Ace::Core::CLI::Error, "--child requires --after to specify the parent job"
            end

            # Validate: adding child would not exceed MAX_DEPTH
            if options[:child] && options[:after]
              parsed = Atoms::JobNumbering.parse(options[:after])
              max_depth = Atoms::JobNumbering::MAX_DEPTH
              if parsed[:depth] >= max_depth
                raise Ace::Core::CLI::Error,
                      "Cannot add child: would exceed maximum nesting depth of #{max_depth + 1} levels " \
                      "(parent '#{options[:after]}' is at depth #{parsed[:depth]})"
              end
            end

            instructions = options[:instructions] || "Complete this step and report: ace-coworker report report.md"

            executor = Organisms::WorkflowExecutor.new
            result = executor.add(
              name,
              instructions,
              after: options[:after],
              as_child: options[:child]
            )

            unless options[:quiet]
              added = result[:added]
              puts "Created: jobs/#{File.basename(added.file_path)}"
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
                puts "Renumbered jobs:"
                result[:renumbered].each do |old_num|
                  new_num = Atoms::JobNumbering.shift_number(old_num, 1)
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
        end
      end
    end
  end
end
