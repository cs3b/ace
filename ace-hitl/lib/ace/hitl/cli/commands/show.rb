# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Hitl
    module CLI
      module Commands
        class Show < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show HITL event details"

          argument :ref, required: true, desc: "HITL reference (full ID or shortcut)"

          option :path, type: :boolean, desc: "Print file path only"
          option :content, type: :boolean, desc: "Print raw markdown content"
          option :scope, type: :string, desc: "Scope (current, all)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            scope = validate_scope(options[:scope])
            manager = Ace::Hitl::Organisms::HitlManager.new
            begin
              resolved = manager.show(ref, scope: scope)
            rescue Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError => e
              candidates = e.matches.map(&:file_path).join(", ")
              raise Ace::Support::Cli::Error.new(
                "HITL event '#{ref}' is ambiguous across scope '#{scope || "all"}'. Candidates: #{candidates}"
              )
            end
            raise Ace::Support::Cli::Error.new("HITL event '#{ref}' not found") unless resolved
            event = resolved[:event]
            resolved_location = format_resolved_location(resolved)

            if options[:path]
              puts event.file_path
            elsif options[:content]
              puts resolved_location if resolved_location
              puts File.read(event.file_path)
            else
              puts "ID: #{event.id}"
              puts "Title: #{event.title}"
              puts "Status: #{event.status}"
              puts "Kind: #{event.kind}"
              puts "Tags: #{event.tags.join(", ")}"
              puts "Questions: #{event.questions.join(" | ")}"
              puts "Answer: #{event.answer || "(none)"}"
              puts resolved_location if resolved_location
              puts "Path: #{event.file_path}"
            end
          end

          private

          def validate_scope(raw_scope)
            return nil if raw_scope.nil?

            scope = raw_scope.to_s.strip
            allowed = Ace::Hitl::Molecules::WorktreeScopeResolver::VALID_SCOPES
            return scope if allowed.include?(scope)

            raise Ace::Support::Cli::Error.new("Invalid scope '#{raw_scope}'. Allowed: #{allowed.join(", ")}")
          end

          def format_resolved_location(resolved)
            return nil unless resolved[:resolved_outside_current]

            worktree = resolved[:resolved_worktree_root] || "(unknown worktree)"
            "Resolved Location: worktree=#{worktree} path=#{resolved[:event].file_path}"
          end
        end
      end
    end
  end
end
