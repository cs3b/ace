# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../molecules/hitl_display_formatter"

module Ace
  module Hitl
    module CLI
      module Commands
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List HITL events"

          option :status, type: :string, aliases: %w[-s], desc: "Filter by status"
          option :kind, type: :string, aliases: %w[-k], desc: "Filter by kind"
          option :type, type: :string, desc: "Filter by type (question, report)"
          option :delivery, type: :string, desc: "Filter by delivery state (undelivered, delivered)"
          option :tags, type: :string, aliases: %w[-T], desc: "Filter by tags (comma-separated)"
          option :in, type: :string, aliases: %w[-i], desc: "Folder filter (next, all, archive)"
          option :scope, type: :string, desc: "Scope (current, all)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            scope = validate_scope(options[:scope])
            status = options[:status]
            kind = options[:kind]
            type = options[:type]
            validate_type!(type) if type
            delivery = options[:delivery]
            validate_delivery!(delivery) if delivery
            tags = parse_tags(options[:tags])
            in_folder = options[:in] || "next"

            manager = Ace::Hitl::Organisms::HitlManager.new
            events = manager.list(status: status, kind: kind, type: type, delivery: delivery,
              tags: tags, in_folder: in_folder, scope: scope)

            puts Ace::Hitl::Molecules::HitlDisplayFormatter.format_list(
              events,
              total_count: manager.last_list_total,
              global_folder_stats: manager.last_folder_counts
            )
          end

          private

          def parse_tags(raw)
            return [] unless raw

            raw.split(",").map(&:strip).reject(&:empty?)
          end

          def validate_type!(type)
            allowed = %w[question report]
            return if allowed.include?(type)

            raise Ace::Support::Cli::Error.new("Invalid type '#{type}'. Allowed: #{allowed.join(", ")}")
          end

          def validate_delivery!(delivery)
            allowed = %w[undelivered delivered]
            return if allowed.include?(delivery)

            raise Ace::Support::Cli::Error.new("Invalid delivery filter '#{delivery}'. Allowed: #{allowed.join(", ")}")
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
