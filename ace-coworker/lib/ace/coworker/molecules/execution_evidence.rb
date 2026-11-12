# frozen_string_literal: true
require "json"
require "yaml"
require "date"

module Ace::Coworker::Molecules
  # Read only the executor reference and review paths named in this assignment's
  # reports. No global session discovery or cumulative usage counter.
  class ExecutionEvidence
    MAX_BYTES = 64 * 1024 * 1024
    def initialize(project_root:)
      @root = project_root
    end

    def read(config)
      document = yaml(config.source_path)
      executions = []
      session_path = document.dig("execution", "session_path") || document.dig("execution", "resume_transcript")
      executions << pi_session(session_path) if session_path
      id = config.assignment.to_s
      if id.match?(/\A[a-zA-Z0-9][\w.-]*\z/)
        paths = Dir.glob(File.join(@root, ".ace-local/assign", id, "reports/*.r.md"))
        refs = paths.flat_map do |path|
          File.read(path).scan(%r{(?:/[^\s`"<>]+)?\.ace-local/review/sessions/[a-zA-Z0-9_.-]+})
        end.uniq
        refs.each do |ref|
          directory = File.expand_path(ref, @root)
          next unless directory.start_with?(File.join(@root, ".ace-local/review/sessions/"))
          multi = yaml(File.join(directory, "metadata.yml"))["models"]
          if multi.is_a?(Array) && multi.all? { |entry| entry.is_a?(Hash) }
            multi.each_with_index do |metadata, index|
              executions << review_execution(metadata, "#{directory}##{index}", File.join(directory, "metadata.yml"))
            end
          else
            path = File.join(directory, "llm_metadata.yml")
            executions << review_execution(yaml(path), directory, path)
          end
        end
      end
      {"executions" => executions.uniq { |row| row["id"] },
        "coverage" => "referenced executions only; unavailable usage is unknown; no quota or cost estimate"}
    rescue SystemCallError, JSON::ParserError, Psych::Exception, TypeError
      {"executions" => [], "coverage" => "unknown: execution evidence unavailable"}
    end

    private

    def review_execution(metadata, id, path)
      {"id" => id, "kind" => "review", "status" => metadata["status"],
        "model" => metadata.dig("execution", "model"),
        "requested_selector" => metadata["requested_selector"],
        "usage" => review_usage(metadata["usage"]), "evidence" => path}
    end

    def yaml(path)
      return {} unless path && File.file?(path) && File.size(path) <= MAX_BYTES
      value = YAML.safe_load_file(path, permitted_classes: [Time, Date, Symbol], aliases: false)
      value.is_a?(Hash) ? JSON.parse(JSON.generate(value)) : {}
    end

    def review_usage(usage)
      return nil unless usage.is_a?(Hash)
      {"input" => usage["input_tokens"], "output" => usage["output_tokens"],
        "cacheRead" => usage["cached_tokens"], "cacheWrite" => usage["cache_write_tokens"]}
    end

    def pi_session(path)
      base = {"id" => path, "kind" => "pi", "evidence" => path, "models" => nil, "usage" => nil}
      return base unless path.is_a?(String) && File.file?(path) && File.size(path) <= MAX_BYTES
      seen = {}
      messages = File.foreach(path).filter_map do |line|
        entry = JSON.parse(line)
        next unless entry["type"] == "message" && entry.dig("message", "role") == "assistant"
        next if entry["id"] && seen[entry["id"]]
        seen[entry["id"]] = true if entry["id"]
        entry["message"]
      end
      usage = %w[input output cacheRead cacheWrite].to_h do |key|
        values = messages.map { |message| message.dig("usage", key) }
        [key, !values.empty? && values.all? { |value| value.is_a?(Numeric) && value >= 0 } ? values.sum : nil]
      end
      base.merge("models" => messages.map { |message| message.values_at("provider", "model") }.uniq,
        "usage" => usage, "status" => messages.last&.fetch("stopReason", nil))
    end
  end
end
