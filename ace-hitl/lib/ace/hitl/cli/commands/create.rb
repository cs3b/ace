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

          option :kind, type: :string, aliases: %w[-k], desc: "Kind: clarification, decision, approval (questions only)"
          option :type, type: :string, aliases: %w[-t], desc: "Type: question (default), report"
          option :result, type: :string, desc: "Report result: success, error (reports only)"
          option :body, type: :string, repeat: true, aliases: %w[-b], desc: "Report content line (repeatable, reports only)"
          option :task, type: :string, desc: "Task reference"
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

            type = options[:type]
            validate_type!(type) if type

            questions = Array(options[:question]).map(&:strip).reject(&:empty?)
            body = Array(options[:body]).map(&:strip).reject(&:empty?)
            result = options[:result]
            validate_combinations!(type, result: result, body: body, questions: questions,
              resume: options[:resume], kind: kind)
            validate_result!(result) if result

            tags = parse_tags(options[:tags])

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = manager.create(
              title,
              kind: kind,
              type: type,
              result: result,
              task: options[:task],
              body: body,
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

          def validate_type!(type)
            allowed = %w[question report]
            return if allowed.include?(type)

            raise Ace::Support::Cli::Error.new("Invalid type '#{type}'. Allowed: #{allowed.join(", ")}")
          end

          def validate_result!(result)
            allowed = %w[success error]
            return if allowed.include?(result)

            raise Ace::Support::Cli::Error.new("Invalid result '#{result}'. Allowed: #{allowed.join(", ")}")
          end

          def validate_combinations!(type, result:, body:, questions:, resume:, kind: nil)
            report = type == "report"
            if report
              unless result
                raise Ace::Support::Cli::Error.new("--type report requires --result success|error")
              end
              if questions.any?
                raise Ace::Support::Cli::Error.new("--question cannot be combined with --type report; use --body lines")
              end
              if resume
                raise Ace::Support::Cli::Error.new("--resume cannot be combined with --type report; reports do not resume")
              end
              if kind
                raise Ace::Support::Cli::Error.new("--kind cannot be combined with --type report; kinds apply to questions only")
              end
            else
              if result
                raise Ace::Support::Cli::Error.new("--result is only valid with --type report")
              end
              if body.any?
                raise Ace::Support::Cli::Error.new("--body is only valid with --type report")
              end
            end
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
