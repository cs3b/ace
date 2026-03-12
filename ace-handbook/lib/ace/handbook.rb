# frozen_string_literal: true

require "ace/support/config"

require_relative "handbook/version"
require_relative "handbook/atoms/provider_registry"
require_relative "handbook/models/skill_document"
require_relative "handbook/molecules/skill_projection"
require_relative "handbook/organisms/skill_inventory"
require_relative "handbook/organisms/provider_syncer"
require_relative "handbook/organisms/status_collector"

module Ace
  module Handbook
    class << self
      def config
        @config ||= Ace::Support::Config.create(
          gem_path: File.expand_path("../..", __dir__),
          cache_namespaces: true
        )
      end

      def project_root(start_path: Dir.pwd)
        Ace::Support::Config.find_project_root(start_path: start_path) || Dir.pwd
      end
    end
  end
end
