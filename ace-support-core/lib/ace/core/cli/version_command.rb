# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Core
    module CLI
      # Helper for creating standard version commands in ace-support-cli registries.
      module VersionCommand
        def self.build(gem_name:, version:)
          Class.new(Ace::Support::Cli::Command) do
            @gem_name = gem_name
            @version = version

            class << self
              attr_reader :gem_name, :version
            end

            desc "Show version information"

            def call(*)
              puts "#{self.class.gem_name} #{self.class.version}"
              0
            end
          end
        end

        def self.module(gem_name:, version:)
          Module.new do
            define_method(:show_version) do
              puts "#{gem_name} #{version.call}"
              0
            end
          end
        end
      end
    end
  end
end
