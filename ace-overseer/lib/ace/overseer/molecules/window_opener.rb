# frozen_string_literal: true

require "ace/runtime"

module Ace
  module Overseer
    module Molecules
      # Opens the task's terminal window through the runtime contract.
      # The window is named after the worktree basename under the shared
      # naming policy and rooted at the worktree path.
      class WindowOpener
        def initialize(runtime: nil, config: nil, env: ENV)
          @runtime = runtime
          @config = config || Ace::Overseer.config
          @env = env
        end

        def open(worktree_path:, preset: nil)
          name = Ace::Runtime.sanitize_name(File.basename(worktree_path.to_s))
          adapter.ensure_window(
            name: name,
            root: File.expand_path(worktree_path.to_s),
            preset: preset
          )
          name
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to open terminal window for #{worktree_path}: #{e.message}"
        end

        private

        attr_reader :config, :env

        def adapter
          @adapter ||= @runtime || Ace::Runtime::Molecules::RuntimeSelector.new(
            config: {runtime: config["runtime"]},
            env: env
          ).resolve
        end
      end
    end
  end
end
