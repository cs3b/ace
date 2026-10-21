# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module VersionCommand
          # Statically declared command class: Spinel bakes the class
          # graph at compile time (Class.new is unsupported in AOT).
          # build returns an instance; Runner dispatches instance
          # targets via #call.
          class Command < ::Ace::Support::Cli::Command
            desc "Show version information"

            attr_reader :gem_name, :version

            def initialize(gem_name:, version:)
              @gem_name = gem_name
              @version = version
            end

            def call(**_params)
              puts "#{gem_name} #{version}"
              0
            end
          end

          def self.build(gem_name:, version:)
            Command.new(gem_name: gem_name, version: version)
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
end
