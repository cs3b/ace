# frozen_string_literal: true

require "ace/support/cli"
require "ace/support/items"

module Ace
  module Hitl
    module CLI
      module Commands
        class Update < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Update HITL event metadata and/or answer"

          argument :ref, required: true, desc: "HITL reference (full ID or shortcut)"

          option :set, type: :string, repeat: true, desc: "Set field: key=value"
          option :add, type: :string, repeat: true, desc: "Add field: key=value"
          option :remove, type: :string, repeat: true, desc: "Remove field: key=value"
          option :"move-to", type: :string, aliases: %w[-m], desc: "Move to folder (archive, next)"
          option :answer, type: :string, desc: "Write ## Answer body and mark answered"
          option :resume, type: :boolean, desc: "Dispatch resume after answer using waiter/session metadata"
          option :scope, type: :string, desc: "Scope (current, all)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            set_args = Array(options[:set])
            add_args = Array(options[:add])
            remove_args = Array(options[:remove])
            move_to = options[:"move-to"]
            answer = options[:answer]
            resume = options[:resume] == true
            scope = validate_scope(options[:scope])

            if set_args.empty? && add_args.empty? && remove_args.empty? && move_to.nil? && answer.nil? && !resume
              raise Ace::Support::Cli::Error.new("No update operations specified")
            end

            set_hash = parse_kv_pairs(set_args)
            add_hash = parse_kv_pairs(add_args)
            remove_hash = parse_kv_pairs(remove_args)

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = begin
              manager.update(
                ref,
                set: set_hash,
                add: add_hash,
                remove: remove_hash,
                move_to: move_to,
                answer: answer,
                scope: scope
              )
            rescue Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError => e
              candidates = e.matches.map(&:file_path).join(", ")
              raise Ace::Support::Cli::Error.new(
                "HITL event '#{ref}' is ambiguous across scope '#{scope || "all"}'. Candidates: #{candidates}"
              )
            end

            raise Ace::Support::Cli::Error.new("HITL event '#{ref}' not found") unless event

            if move_to
              folder_info = event.special_folder || "root"
              puts "HITL event updated: #{event.id} #{event.title} -> #{folder_info}"
            else
              puts "HITL event updated: #{event.id} #{event.title}"
            end

            return unless resume

            dispatch = manager.dispatch_resume(event.id, scope: scope)
            case dispatch[:status]
            when :waiter_active
              puts "Resume dispatch skipped: active waiter lease detected."
            when :dispatched
              puts "Resume dispatched: mode=#{dispatch[:mode]} details=#{dispatch[:details]}"
              puts "HITL event archived after successful dispatch."
            when :no_answer
              raise Ace::Support::Cli::Error.new("Cannot resume '#{event.id}' without an answer")
            when :failed
              raise Ace::Support::Cli::Error.new(dispatch[:error] || "Resume dispatch failed")
            else
              raise Ace::Support::Cli::Error.new("Resume dispatch failed: unexpected status #{dispatch[:status]}")
            end
          end

          private

          def parse_kv_pairs(args)
            result = {}
            args.each do |arg|
              unless arg.include?("=")
                raise Ace::Support::Cli::Error.new("Invalid format '#{arg}': expected key=value")
              end

              parsed = Ace::Support::Items::Atoms::FieldArgumentParser.parse([arg])
              parsed.each do |key, value|
                result[key] = if result.key?(key)
                  Array(result[key]) + Array(value)
                else
                  value
                end
              end
            rescue Ace::Support::Items::Atoms::FieldArgumentParser::ParseError => e
              raise Ace::Support::Cli::Error.new("Invalid argument '#{arg}': #{e.message}")
            end
            result
          end

          def validate_scope(raw_scope)
            return nil if raw_scope.nil?

            scope = raw_scope.to_s.strip
            allowed = Ace::Hitl::Molecules::WorktreeScopeResolver::VALID_SCOPES
            return scope if allowed.include?(scope)

            raise Ace::Support::Cli::Error.new("Invalid scope '#{raw_scope}'. Allowed: #{allowed.join(", ")}")
          end
        end
      end
    end
  end
end
