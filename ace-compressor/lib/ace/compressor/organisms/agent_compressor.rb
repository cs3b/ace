# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Compressor
    module Organisms
      # Agent mode keeps exact ContextPack structure and asks the LLM to rewrite
      # only compressible payloads. The model never emits headers, file markers,
      # or section markers.
      class AgentCompressor
        PAYLOAD_PREFIXES = ["SUMMARY|", "FACT|"].freeze
        PROTECTED_PREFIXES = [
          "RULE|", "CONSTRAINT|", "CMD|", "TABLE|", "U|", "CODE|", "PROBLEMS|",
          "EXAMPLE|", "EXAMPLE_REF|", "FILES|", "TREE|", "LOSS|"
        ].freeze
        LIST_REWRITE_MIN_ITEMS = 5
        LIST_REWRITE_MIN_BYTES = 140
        LIST_STOPWORDS = %w[
          a an and as at by for from in into is of on or that the this to via with within
        ].freeze
        LIST_TOKEN_MAP = {
          "architecture" => "arch",
          "architectural" => "arch",
          "configuration" => "config",
          "documentation" => "docs",
          "generation" => "gen",
          "management" => "mgmt",
          "repository" => "repo",
          "repositories" => "repos",
          "development" => "dev",
          "integration" => "integr",
          "execution" => "exec",
          "reporting" => "reports",
          "organization" => "org",
          "organizations" => "orgs",
          "capabilities" => "caps",
          "capability" => "cap",
          "foundation" => "base",
          "tracking" => "track",
          "powered" => "pwr",
          "detected" => "detect",
          "matching" => "match"
        }.freeze

        attr_reader :ignored_paths

        def initialize(paths, verbose: false, shell_runner: nil)
          @exact = ExactCompressor.new(paths, verbose: verbose, mode_label: "agent")
          @shell_runner = shell_runner || method(:default_shell_runner)
        end

        def call
          compress_sources(resolve_sources)
        end

        def resolve_sources
          @exact.resolve_sources
        end

        def ignored_paths
          @exact.ignored_paths
        end

        def compress_sources(sources)
          exact_output = @exact.compress_sources(sources)
          exact_lines = normalize_output_lines(exact_output)
          return exact_output if exact_lines.empty?

          job = build_rewrite_job(exact_lines)
          rewrites = rewrite_payloads(job[:records])
          rebuild_output(job[:entries], rewrites)
        end

        private

        def build_rewrite_job(exact_lines)
          entries = [Ace::Compressor::Models::ContextPack.header("agent")]
          records = []
          current_file = nil
          current_section = nil
          next_id = 1

          Array(exact_lines).drop(1).each do |line|
            if line.start_with?("FILE|")
              current_file = line.sub("FILE|", "").strip
              entries << line
              next
            end

            if line.start_with?("SEC|")
              current_section = line.sub("SEC|", "").strip
              entries << line
              next
            end

            record = rewrite_record_for(line, current_file, current_section, next_id)
            if record
              records << record
              entries << { rewrite_id: record[:id], original_line: line }
              next_id += 1
            else
              entries << line
            end
          end

          { entries: entries, records: records }
        end

        def rewrite_record_for(line, current_file, current_section, next_id)
          return nil if line.start_with?(*PROTECTED_PREFIXES)

          if line.start_with?(*PAYLOAD_PREFIXES)
            type = line.split("|", 2).first
            return {
              id: record_id(next_id),
              type: type,
              file: current_file,
              section: current_section,
              payload: record_payload(line)
            }
          end

          return nil unless line.start_with?("LIST|")

          name, items = parse_list_line(line)
          return nil unless list_rewrite_eligible?(line, items)

          {
            id: record_id(next_id),
            type: "LIST",
            file: current_file,
            section: current_section,
            name: name,
            items: items
          }
        end

        def list_rewrite_eligible?(line, items)
          return false if items.empty?

          items.length >= LIST_REWRITE_MIN_ITEMS || line.bytesize >= LIST_REWRITE_MIN_BYTES
        end

        def rewrite_payloads(records)
          return {} if records.empty?

          prompt = compose_prompt(records)
          response = invoke_agent(prompt)
          extract_rewrites(records, response)
        rescue Ace::Compressor::Error, JSON::ParserError
          {}
        end

        def compose_prompt(records)
          <<~PROMPT
            #{agent_template}

            <records_json>
            #{JSON.pretty_generate("records" => prompt_records(records))}
            </records_json>
          PROMPT
        end

        def prompt_records(records)
          Array(records).map do |record|
            base = {
              "id" => record[:id],
              "type" => record[:type],
              "file" => record[:file],
              "section" => record[:section]
            }

            if record[:type] == "LIST"
              base.merge("items" => record[:items])
            else
              base.merge("payload" => record[:payload])
            end
          end
        end

        def agent_template
          @agent_template ||= execute_command(["ace-bundle", agent_template_uri]).strip
        end

        def invoke_agent(prompt)
          execute_command(["ace-llm", agent_model, prompt]).strip
        end

        def extract_rewrites(records, response)
          parsed = parse_agent_response(response)
          rewrites = {}
          records_by_id = Array(records).each_with_object({}) { |record, hash| hash[record[:id]] = record }

          Array(parsed.fetch("records", [])).each do |candidate|
            original = records_by_id[candidate["id"]]
            next unless original

            rewrite = normalized_rewrite(original, candidate)
            rewrites[original[:id]] = rewrite if rewrite
          end

          rewrites
        end

        def parse_agent_response(response)
          payload = response.to_s.strip
          payload = payload.sub(/\A```(?:json)?\s*/i, "")
          payload = payload.sub(/\s*```\z/, "")
          JSON.parse(payload)
        end

        def normalized_rewrite(original, candidate)
          case original[:type]
          when "SUMMARY", "FACT"
            payload = normalize_payload_text(candidate["payload"])
            return nil if payload.empty?

            { type: original[:type], payload: payload }
          when "LIST"
            items = Array(candidate["items"]).map { |item| normalize_list_item(item) }
            return nil unless items.length == original[:items].length
            return nil if items.any?(&:empty?)

            { type: "LIST", name: original[:name], items: items }
          end
        end

        def rebuild_output(entries, rewrites)
          Array(entries).map do |entry|
            next entry if entry.is_a?(String)

            rewrite = rewrites[entry[:rewrite_id]]
            rewrite ? render_rewrite(rewrite) : entry[:original_line]
          end.join("\n")
        end

        def render_rewrite(rewrite)
          case rewrite[:type]
          when "SUMMARY", "FACT"
            "#{rewrite[:type]}|#{rewrite[:payload]}"
          when "LIST"
            "LIST|#{rewrite[:name]}|[#{rewrite[:items].join(",")}]"
          else
            raise Ace::Compressor::Error, "Unsupported agent rewrite type: #{rewrite[:type]}"
          end
        end

        def parse_list_line(line)
          _prefix, name, raw_items = line.split("|", 3)
          items = raw_items.to_s.sub(/\A\[/, "").sub(/\]\z/, "").split(",").map(&:strip).reject(&:empty?)
          [name.to_s, items]
        end

        def record_id(index)
          "r#{index}"
        end

        def normalize_output_lines(output)
          output.to_s.lines.map(&:strip).reject(&:empty?)
        end

        def normalize_payload_text(text)
          text.to_s.gsub(/\s+/, " ").strip
        end

        def normalize_list_item(text)
          tokens = text.to_s.downcase.gsub(/[^a-z0-9]+/, "_").split("_").reject(&:empty?)
          tokens = compact_list_tokens(tokens)
          tokens.join("_")
        end

        def compact_list_tokens(tokens)
          compacted = Array(tokens).filter_map do |token|
            next if LIST_STOPWORDS.include?(token)

            LIST_TOKEN_MAP.fetch(token, token)
          end

          compacted = compacted.each_with_object([]) do |token, result|
            result << token unless result.last == token
          end

          compacted.empty? ? Array(tokens).first(1) : compacted
        end

        def record_payload(line)
          line.to_s.split("|", 2).last.to_s
        end

        def agent_model
          @agent_model ||= begin
            config = Ace::Compressor.config
            model = config["agent_model"].to_s.strip
            model = config["agent_provider"].to_s.strip if model.empty?
            raise Ace::Compressor::Error, "Agent model not configured: set compressor.agent_model" if model.empty?
            model
          end
        end

        def agent_template_uri
          @agent_template_uri ||= begin
            template_uri = Ace::Compressor.config["agent_template_uri"].to_s.strip
            raise Ace::Compressor::Error, "Agent template URI not configured: set compressor.agent_template_uri" if template_uri.empty?
            template_uri
          end
        end

        def execute_command(command)
          stdout, stderr, status = @shell_runner.call(command)
          return stdout if status.success?

          details = stderr.to_s.strip
          details = stdout.to_s.strip if details.empty?
          raise Ace::Compressor::Error, "#{command.first} failed: #{details}"
        end

        def default_shell_runner(command)
          Open3.capture3(*command)
        end
      end
    end
  end
end
