# frozen_string_literal: true

# Dead-code stubs for ace-llm inside Spinel-compiled ace binaries.
#
# ace-support-config's setup_doctor lazily requires ace/llm to probe
# LLM provider health. Those methods are unreachable from CLI commands
# compiled here, but Spinel's whole-program analysis must still type
# them. Every stub raises if ever invoked; all call sites rescue
# StandardError and degrade to nil/[]. If ace-llm ever lands on this
# path for real, the answer is compiling ace-llm too, not these stubs.

module Ace
  module LLM
    module Molecules
      class ClientRegistry
        def initialize(options = nil)
          raise "ace-llm unavailable in compiled binary"
        end

        def list_providers_with_status
          raise "ace-llm unavailable in compiled binary"
        end

        def available_aliases
          raise "ace-llm unavailable in compiled binary"
        end

        def get_provider(_name)
          raise "ace-llm unavailable in compiled binary"
        end
      end

      class LlmAliasResolver
        def initialize(alias_map: nil, registry: nil)
          raise "ace-llm unavailable in compiled binary"
        end
      end

      class ProviderModelParser
        class ParsedModel
          def invalid?
            true
          end

          def provider
            ""
          end

          def model
            ""
          end

          def error
            "ace-llm unavailable in compiled binary"
          end
        end

        def initialize(alias_resolver: nil, registry: nil)
          raise "ace-llm unavailable in compiled binary"
        end

        def parse(_text)
          ParsedModel.new
        end
      end
    end

    module Models
      class RoleConfig
        def candidates_for(_role)
          raise "ace-llm unavailable in compiled binary"
        end
      end
    end
  end
end
