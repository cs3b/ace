# frozen_string_literal: true

require "fileutils"
require "ace/support/config"

require_relative "demo/version"
require_relative "demo/atoms/vhs_command_builder"
require_relative "demo/atoms/demo_name_sanitizer"
require_relative "demo/atoms/demo_comment_formatter"
require_relative "demo/atoms/tape_metadata_parser"
require_relative "demo/atoms/tape_search_dirs"
require_relative "demo/atoms/attach_output_printer"
require_relative "demo/atoms/tape_content_generator"
require_relative "demo/atoms/demo_yaml_parser"
require_relative "demo/atoms/yaml_record_planner"
require_relative "demo/atoms/vhs_tape_compiler"
require_relative "demo/atoms/playback_speed_parser"
require_relative "demo/models/execution_result"
require_relative "demo/molecules/vhs_executor"
require_relative "demo/molecules/tape_resolver"
require_relative "demo/molecules/tape_writer"
require_relative "demo/molecules/tape_scanner"
require_relative "demo/molecules/demo_sandbox_builder"
require_relative "demo/molecules/demo_teardown_executor"
require_relative "demo/molecules/gh_asset_uploader"
require_relative "demo/molecules/inline_recorder"
require_relative "demo/molecules/media_retimer"
require_relative "demo/molecules/demo_comment_poster"
require_relative "demo/organisms/demo_recorder"
require_relative "demo/organisms/demo_attacher"
require_relative "demo/organisms/tape_creator"
require_relative "demo/cli"

module Ace
  module Demo
    class Error < StandardError; end
    class TapeNotFoundError < Error; end
    class DemoYamlParseError < Error; end
    class VhsNotFoundError < Error; end
    class VhsExecutionError < Error; end
    class FfmpegNotFoundError < Error; end
    class MediaRetimeError < Error; end
    class GhAuthenticationError < Error; end
    class PrNotFoundError < Error; end
    class GhUploadError < Error; end
    class GhCommentError < Error; end
    class GhCommandError < Error; end
    class TapeAlreadyExistsError < Error; end

    @config_mutex = Mutex.new

    def self.gem_root
      @gem_root ||= Gem.loaded_specs["ace-demo"]&.gem_dir ||
        File.expand_path("../..", __dir__)
    end

    def self.config
      return @config if defined?(@config) && @config

      @config_mutex.synchronize do
        @config ||= load_config
      end
    end

    def self.reset_config!
      @config_mutex.synchronize do
        @config = nil
      end
    end

    def self.load_config
      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      resolver.resolve_namespace("demo").data
    rescue => e
      warn "ace-demo config load failed (#{e.class}): #{e.message}. Using defaults."
      {}
    end
    private_class_method :load_config
  end
end
