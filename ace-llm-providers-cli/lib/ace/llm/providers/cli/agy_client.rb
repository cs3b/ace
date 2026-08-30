# frozen_string_literal: true

require "json"

require_relative "cli_args_support"
require_relative "atoms/execution_context"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Antigravity CLI
        class AgyClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          API_BASE_URL = "https://antigravity.google"
          DEFAULT_GENERATION_CONFIG = {}.freeze
          DEFAULT_MODEL = "gemini-3.5-flash-medium"
          DEFAULT_MAX_PROMPT_LENGTH = 100_000

          def initialize(model: nil, **options)
            @model = model || DEFAULT_MODEL
            @options = options
            @generation_config = options[:generation_config] || {}
          end

          def self.provider_name
            "agy"
          end

          def needs_credentials?
            false
          end

          def list_models
            [
              {id: "gemini-3.7-flash-high", name: "Gemini 3.7 Flash (High)", context_size: 1_000_000},
              {id: "gemini-3.7-flash-medium", name: "Gemini 3.7 Flash (Medium)", context_size: 1_000_000},
              {id: "gemini-3.6-flash-high", name: "Gemini 3.6 Flash (High)", context_size: 1_000_000},
              {id: "gemini-3.6-flash-medium", name: "Gemini 3.6 Flash (Medium)", context_size: 1_000_000},
              {id: "gemini-3.5-flash-medium", name: "Gemini 3.5 Flash (Medium)", context_size: 1_000_000},
              {id: "gemini-3.1-pro-high", name: "Gemini 3.1 Pro (High)", context_size: 1_000_000},
              {id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6 (Thinking)", context_size: 200_000}
            ]
          end

          def generate(messages, **options)
            validate_agy_availability!
            validate_supported_options!(options)

            prompt = format_messages_as_prompt(prepare_messages(messages, options))
            prompt = build_full_prompt(prompt, options)
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )

            cmd = build_agy_command(prompt, options)
            stdout, stderr, status = execute_agy_command(cmd, working_dir: working_dir, options: options)

            parse_agy_response(stdout, stderr, status, prompt)
          rescue => e
            handle_agy_error(e)
          end

          private

          def prepare_messages(messages, options)
            return messages if messages.is_a?(String)

            process_messages_with_system_append(messages, options[:system_append])
          end

          def format_messages_as_prompt(messages)
            return messages if messages.is_a?(String)

            messages.map do |msg|
              role = msg[:role] || msg["role"]
              content = msg[:content] || msg["content"]

              case role
              when "system"
                "System: #{content}"
              when "user"
                "User: #{content}"
              when "assistant"
                "Assistant: #{content}"
              else
                content
              end
            end.join("\n\n")
          end

          def build_full_prompt(prompt, options)
            prompt_str = prompt.to_s
            return prompt_str if prompt_str.start_with?("System:")

            system_content = options[:system_instruction] ||
              options[:system] ||
              options[:system_prompt] ||
              @generation_config[:system_prompt]

            return prompt_str unless system_content

            "System: #{system_content}\n\n#{prompt_str}"
          end

          def agy_available?
            system("which", "agy", out: File::NULL, err: File::NULL)
          end

          def validate_agy_availability!
            return if agy_available?

            raise Ace::LLM::ProviderError,
              "Antigravity CLI not found. Install with: curl -fsSL https://antigravity.google/cli/install.sh | bash"
          end

          def validate_supported_options!(options)
            unsupported = %i[temperature max_tokens top_p top_k]
              .select { |key| options[key] }
            return if unsupported.empty?

            raise Ace::LLM::ProviderError,
              "Antigravity CLI does not support #{unsupported.join(", ")} through ace-llm; use documented cli_args instead"
          end

          def build_agy_command(prompt, options)
            args = normalized_cli_args(options)
            reject_stream_input_args!(args)
            reject_oversized_prompt!(prompt)

            cmd = ["agy", "-p", prompt.to_s, "--output-format", "json"]
            cmd << "--model" << @model if @model
            cmd << "--print-timeout" << normalize_print_timeout(options[:timeout]) if options[:timeout]
            cmd << "--sandbox" if options[:sandbox]
            cmd.concat(args)
            cmd
          end

          def reject_stream_input_args!(args)
            flag = find_conflicting_cli_arg(args, ["--input-format"])
            return unless flag

            raise Ace::LLM::ProviderError,
              "Antigravity one-shot mode does not support cli arg #{flag}; stream-json input requires stdin-driven sessions"
          end

          def reject_oversized_prompt!(prompt)
            prompt_bytesize = prompt.to_s.bytesize
            max_length = @generation_config[:max_prompt_length] || @options[:max_prompt_length] || DEFAULT_MAX_PROMPT_LENGTH
            return if prompt_bytesize <= max_length

            raise Ace::LLM::ProviderError,
              "Antigravity CLI prompt bytesize #{prompt_bytesize} exceeds configured limit #{max_length}. " \
              "Use a provider with file/stdin prompt delivery or lower the prompt size."
          end

          def normalize_print_timeout(timeout)
            value = timeout.to_s
            return "#{value}s" if value.match?(/\A\d+\z/)

            value
          end

          def execute_agy_command(cmd, working_dir:, options:)
            timeout_val = options[:timeout] || @options[:timeout] || 120
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              stdin_data: "",
              chdir: working_dir,
              env: options[:subprocess_env],
              command_prefix: options[:subprocess_command_prefix],
              provider_name: "Antigravity"
            )
          end

          def parse_agy_response(stdout, stderr, status, prompt)
            response = if stream_json_output?(stdout)
              parse_stream_json(stdout)
            else
              parse_json_or_text(stdout)
            end

            error_message = response["error"].to_s
            run_status = response.fetch("status", status.success? ? "SUCCESS" : "ERROR")
            if !status.success? || run_status != "SUCCESS"
              raise Ace::LLM::ProviderError, build_failure_message(error_message, stderr, stdout, run_status)
            end

            text = extract_response_text(response)
            {
              text: text,
              metadata: build_metadata(response, text, prompt)
            }
          end

          def stream_json_output?(stdout)
            stdout.each_line.lazy.map(&:strip).reject(&:empty?).first.to_s.include?("\"event\"")
          end

          def parse_stream_json(stdout)
            text = +""
            result_payload = nil

            stdout.each_line do |line|
              line = line.strip
              next if line.empty?

              entry = JSON.parse(line)
              case entry["event"]
              when "step_update"
                text << entry.dig("step_update", "text_delta").to_s
              when "result"
                result_payload = entry["result"] || {}
              end
            end

            response = result_payload || {}
            response["response"] = text unless text.empty? || response["response"]
            response
          rescue JSON::ParserError
            {"response" => stdout.to_s.strip}
          end

          def parse_json_or_text(stdout)
            JSON.parse(stdout)
          rescue JSON::ParserError
            {"response" => stdout.to_s.strip}
          end

          def build_failure_message(error_message, stderr, stdout, run_status)
            detail = [error_message, stderr.to_s.strip, stdout.to_s.strip].reject(&:empty?).first
            detail = run_status if detail.nil? || detail.empty?
            "Antigravity CLI failed: #{detail}"
          end

          def extract_response_text(response)
            response["response"] || response["text"] || response.dig("result", "response") || ""
          end

          def build_metadata(response, text, prompt)
            usage = response["usage"] || {}
            prompt_tokens = usage["input_tokens"] || (prompt.to_s.length / 4.0).ceil
            output_tokens = usage["output_tokens"] || (text.to_s.length / 4.0).ceil
            conversation_id = response["conversation_id"]

            metadata = {
              provider: "agy",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: output_tokens,
              total_tokens: usage["total_tokens"] || prompt_tokens + output_tokens,
              finish_reason: response["status"]&.downcase || "success",
              timestamp: Time.now.utc.iso8601
            }
            metadata[:thinking_tokens] = usage["thinking_tokens"] if usage["thinking_tokens"]
            metadata[:cache_read_tokens] = usage["cache_read_tokens"] if usage["cache_read_tokens"]
            metadata[:duration_seconds] = response["duration_seconds"] if response["duration_seconds"]
            metadata[:num_turns] = response["num_turns"] if response["num_turns"]
            metadata[:conversation_id] = conversation_id if conversation_id
            metadata[:session_id] = conversation_id if conversation_id
            metadata
          end

          def handle_agy_error(error)
            raise error
          end
        end
      end
    end
  end
end
