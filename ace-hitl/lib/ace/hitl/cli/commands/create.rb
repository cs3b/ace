# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Hitl
    module CLI
      module Commands
        class Create < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Create HITL event"

          argument :title, required: false, desc: "HITL event title"

          option :kind, type: :string, aliases: %w[-k], desc: "Kind: clarification, decision, approval"
          option :question, type: :string, repeat: true, aliases: %w[-Q], desc: "Question line (repeatable)"
          option :tags, type: :string, aliases: %w[-T], desc: "Comma-separated tags"
          option :assignment, type: :string, desc: "Assignment reference"
          option :step, type: :string, desc: "Step number"
          option :"step-name", type: :string, desc: "Step name"
          option :resume, type: :string, desc: "Resume instructions"
          option :"move-to", type: :string, aliases: %w[-m], desc: "Target folder (archive, next)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title: nil, **options)
            unless title && !title.strip.empty?
              raise Ace::Support::Cli::Error.new("Title required")
            end

            kind = options[:kind]
            validate_kind!(kind) if kind

            questions = Array(options[:question]).map(&:strip).reject(&:empty?)
            tags = parse_tags(options[:tags])

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = manager.create(
              title,
              kind: kind,
              questions: questions,
              tags: tags,
              assignment: options[:assignment],
              step: options[:step],
              step_name: options[:"step-name"],
              resume_instructions: options[:resume],
              move_to: options[:"move-to"]
            )

            folder_info = event.special_folder ? " (#{event.special_folder})" : ""
            puts "HITL event created: #{event.id} #{event.title}#{folder_info}"
            puts "  Path: #{event.file_path}"
          end

          private

          def validate_kind!(kind)
            allowed = %w[clarification decision approval]
            return if allowed.include?(kind)

            raise Ace::Support::Cli::Error.new("Invalid kind '#{kind}'. Allowed: #{allowed.join(", ")}")
          end

          def parse_tags(raw)
            return [] unless raw

            raw.split(",").map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end
