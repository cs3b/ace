# frozen_string_literal: true
require "json"
require "fileutils"
require "tempfile"

module Ace::Overseer::Molecules
  # Start owns the standard session input; Pi owns observation checkpoints.
  class EyesConfiguration
    def self.prepare(root:, recipient:)
      path = File.join(root, ".ace-local/overseer/eyes.json")
      existing = File.file?(path) ? JSON.parse(File.read(path)) : {}
      raise Ace::Overseer::Error, "eyes configuration must be an object" unless existing.is_a?(Hash)
      config = existing.merge("scope" => "all", "recipient" => recipient)
      FileUtils.mkdir_p(File.dirname(path))
      Tempfile.create(["eyes-", ".json"], File.dirname(path)) do |file|
        file.write(JSON.pretty_generate(config) + "\n")
        file.flush
        file.fsync
        File.rename(file.path, path)
      end
      path
    rescue JSON::ParserError, SystemCallError => error
      raise Ace::Overseer::Error, "cannot prepare eyes configuration: #{error.message}"
    end
  end
end
