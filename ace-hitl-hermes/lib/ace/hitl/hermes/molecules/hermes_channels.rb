# frozen_string_literal: true

require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Molecules
        module HermesChannels
          # One shared folder between lab and hermes (spec 8wm.t.vs1 §2).
          # `folder` is the absolute directory path; the message address
          # is `<machine>/<name>/<id>` where `<name>` is the channel (and
          # folder basename) token.
          Channel = Struct.new(:name, :machine, :folder, keyword_init: true) do
            def path
              folder
            end

            def address(id)
              "#{machine}/#{name}/#{id}"
            end
          end

          # The channel registry the plugin owns (rejestr kanalow).
          # Token validation happens here, fail closed; folder existence
          # and writability are re-verified at every folder operation by
          # the Box (a channel may be registered before its folder
          # exists).
          class Registry
            def initialize
              @channels = {}
              @default_name = nil
            end

            def register(name, machine:, folder:)
              name = Atoms::HermesTokens.validate!(name, "channel name")
              machine = Atoms::HermesTokens.validate!(machine, "machine name")
              unless folder.is_a?(String) && File.absolute_path?(folder)
                raise ContractError,
                  "hermes channel #{name} folder must be an absolute directory path " \
                  "(got #{folder.inspect})"
              end
              base = File.basename(folder)
              unless Atoms::HermesTokens.valid?(base)
                raise ContractError,
                  "hermes channel #{name} folder basename must match " \
                  "#{Atoms::HermesTokens::PATTERN.inspect} (got #{base.inspect})"
              end
              if @channels.key?(name)
                raise ContractError, "hermes channel already registered: #{name}"
              end

              @channels[name] = Channel.new(name: name, machine: machine, folder: folder)
              name
            end

            def resolve(name)
              channel = @channels[name]
              unless channel
                raise UnknownChannelError,
                  "unknown hermes channel #{name.inspect} (available: #{available.join(', ')})"
              end
              channel
            end

            def default=(name)
              resolve(name)
              @default_name = name
            end

            def default
              @default_name
            end

            def resolve_default
              unless @default_name
                raise ContractError, "no default hermes channel registered"
              end
              resolve(@default_name)
            end

            def available
              @channels.keys.sort
            end
          end
        end
      end
    end
  end
end
