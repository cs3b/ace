# frozen_string_literal: true

require "digest"
require "fileutils"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module InteractiveStartupPolicy
            module_function

            def tmux_context?(subprocess_env = nil)
              env = normalized_env(subprocess_env)
              !tmux_session_name(env).empty?
            end

            def codex_trust_override(working_dir:, subprocess_env: nil)
              return nil unless tmux_context?(subprocess_env)

              path = working_dir.to_s.strip
              return nil if path.empty?

              %{projects."#{escape_toml_basic_string(path)}".trust_level="trusted"}
            end

            def codex_overlay_home(working_dir:, subprocess_env: nil)
              return nil unless tmux_context?(subprocess_env)

              root = working_dir.to_s.strip
              return nil if root.empty?

              overlay_home = File.join(root, ".ace-local", "llm", "codex-home", Digest::SHA256.hexdigest(root)[0, 12])
              prepare_codex_overlay_home(overlay_home: overlay_home, working_dir: root)
              overlay_home
            end

            def normalized_env(subprocess_env)
              env = ENV.to_h
              return env unless subprocess_env

              subprocess_env.each_with_object(env) do |(key, value), memo|
                memo[key.to_s] = value
              end
            end

            def tmux_session_name(env)
              explicit = env["ACE_TMUX_SESSION"].to_s.strip
              return explicit unless explicit.empty?

              env["TMUX"].to_s.strip
            end

            def escape_toml_basic_string(value)
              value.to_s.gsub("\\", "\\\\\\\\").gsub("\"", "\\\\\"")
            end

            def prepare_codex_overlay_home(overlay_home:, working_dir:)
              codex_dir = File.join(overlay_home, ".codex")
              FileUtils.mkdir_p(codex_dir)

              sync_codex_overlay_links(codex_dir)
              write_codex_overlay_config(codex_dir: codex_dir, working_dir: working_dir)
            end

            def sync_codex_overlay_links(codex_dir)
              source_dir = File.expand_path("~/.codex")
              return unless Dir.exist?(source_dir)

              %w[auth.json installation_id version.json skills rules memories].each do |entry|
                source = File.join(source_dir, entry)
                next unless File.exist?(source)

                target = File.join(codex_dir, entry)
                next if File.exist?(target) || File.symlink?(target)

                File.symlink(source, target)
              end
            end

            def write_codex_overlay_config(codex_dir:, working_dir:)
              source_config = File.expand_path("~/.codex/config.toml")
              base = File.exist?(source_config) ? File.read(source_config) : ""
              trust_block = <<~TOML

                [projects."#{escape_toml_basic_string(working_dir)}"]
                trust_level = "trusted"
              TOML

              target = File.join(codex_dir, "config.toml")
              content = base.include?(trust_block.strip) ? base : "#{base.rstrip}#{trust_block}"
              File.write(target, content)
            end
          end
        end
      end
    end
  end
end
