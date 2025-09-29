# frozen_string_literal: true

require "thor"
require_relative "organisms/config_initializer"
require_relative "organisms/config_diff"

module Ace
  module Core
    class CLI < Thor
      desc "init [GEM]", "Initialize configuration for specific gem or all"
      option :force, type: :boolean, desc: "Overwrite existing files"
      option :dry_run, type: :boolean, desc: "Show what would be done"
      option :global, type: :boolean, desc: "Use ~/.ace instead of ./.ace"
      option :verbose, type: :boolean, desc: "Show detailed output"
      def init(gem = nil)
        initializer = ConfigInitializer.new(
          force: options[:force],
          dry_run: options[:dry_run],
          global: options[:global],
          verbose: options[:verbose]
        )

        if gem
          initializer.init_gem(gem)
        else
          initializer.init_all
        end
      end

      desc "diff", "Compare configs with examples"
      option :global, type: :boolean, desc: "Compare global configs"
      option :local, type: :boolean, desc: "Compare local configs (default)"
      option :file, type: :string, desc: "Compare specific file"
      option :one_line, type: :boolean, desc: "One-line summary per file"
      def diff
        differ = ConfigDiff.new(
          global: options[:global],
          file: options[:file],
          one_line: options[:one_line]
        )

        differ.run
      end

      desc "version", "Show version"
      def version
        puts "ace-core #{Ace::Core::VERSION}"
      end
    end
  end
end