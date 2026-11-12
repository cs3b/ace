# frozen_string_literal: true

require "json"
require "ace/herdr"
require "ace/herdr/molecules/bounded_observation"
require "ace/runtime/molecules/process_identity"
require_relative "eyes_evidence"

module Ace
  module Overseer
    module Molecules
      # Reconstruct Pi's current persisted branch and bind its eyes evidence
      # to the live Herdr pane and process, without persisting another copy.
      class EyesSessionEvidence
        MAX_BYTES = 64 * 1024 * 1024
        MAX_ENTRIES = 200_000
        SESSION_PATH = %r{\A/[^\0]*_([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\.jsonl\z}

        # Preserve exact kernel birth identity on Linux and Darwin. A stale
        # PID or zombie never proves observation readiness.
        class NativeIdentity
          def initialize(birth: Ace::Runtime::Molecules::ProcessIdentity.new)
            @birth = birth
          end

          def capture(pid)
            return nil unless pid.is_a?(Integer) && pid.positive?
            return @birth.capture(pid) if RUBY_PLATFORM.include?("darwin")
            return nil unless RUBY_PLATFORM.include?("linux")
            before = @birth.native_birth(pid)
            return nil unless before
            stat = File.read("/proc/#{pid}/stat")
            match = stat.match(/\A#{pid} \(.*\) ([A-Za-z]) /m)
            return nil unless match && !%w[Z X].include?(match[1])
            uid = File.stat("/proc/#{pid}").uid
            return nil unless @birth.native_birth(pid) == before
            {"pid" => pid, "uid" => uid, "started_at" => before}
          rescue SystemCallError, IOError
            nil
          end
        end

        def initialize(executor: nil, identity: NativeIdentity.new,
          clock: -> { (Time.now.to_f * 1000).to_i },
          file_opener: ->(path) { File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) })
          @executor, @identity, @clock, @file_opener = executor, identity, clock, file_opener
        end

        def ready?(pane:, root:, prompt:, required_sources:, expected_terminal: nil, expected_config: nil)
          executor = @executor || Ace::Herdr::Molecules::BoundedObservation.new(
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
          before = pane_binding(executor, pane)
          return false unless before && (expected_terminal.nil? || before["terminal_id"] == expected_terminal)
          path = before.fetch("path")
          file = @file_opener.call(path)
          stat = file.stat
          return false unless stat.file? && stat.size.between?(1, MAX_BYTES)
          content = file.read(MAX_BYTES + 1)
          return false unless content && content.bytesize == stat.size && content.end_with?("\n")
          again = file.stat
          return false unless [stat.dev, stat.ino, stat.size, stat.mtime] == [again.dev, again.ino, again.size, again.mtime]
          header, branch = branch_for(content)
          return false unless header["cwd"] == root && header["id"].to_s.downcase == before.fetch("session_id").downcase

          eye = branch.reverse.find { |entry| entry["type"] == "custom" && entry["customType"] == EyesEvidence::ENTRY }
          pid = eye&.dig("data", "observerEvidence", "process", "pid")
          return false unless pid.is_a?(Integer) && pid.positive? && foreground?(executor, pane, pid)
          process = @identity.capture(pid)
          return false unless process && process["uid"] == stat.uid
          return false unless EyesEvidence.ready?(branch: branch, root: root, process: process,
            prompt: prompt, required_sources: required_sources, expected_config: expected_config, now_ms: @clock.call)
          # The owner or its session may change while the file is read.
          return false unless @identity.capture(pid) == process && foreground?(executor, pane, pid) && pane_binding(executor, pane) == before
          final = file.stat
          named = File.lstat(path)
          named.file? && !named.symlink? &&
            [stat.dev, stat.ino, stat.size, stat.mtime] == [final.dev, final.ino, final.size, final.mtime] &&
            [stat.dev, stat.ino] == [named.dev, named.ino]
        rescue Ace::Herdr::ExecutorError, SystemCallError, IOError, JSON::ParserError, ArgumentError, TypeError, KeyError
          false
        ensure
          file&.close
        end

        private

        def pane_binding(executor, pane)
          json = executor.pane_get(pane).parsed_json
          row = json.is_a?(Hash) && json["result"].is_a?(Hash) ? json["result"]["pane"] : nil
          return nil unless row.is_a?(Hash) && row["pane_id"] == pane && row["agent"] == "pi" &&
            (row["terminal_id"].is_a?(String) || row["terminal_id"].is_a?(Integer)) && !row["terminal_id"].to_s.empty?
          session = row["agent_session"]
          return nil unless session.is_a?(Hash) && session["agent"] == "pi" && session["kind"] == "path"
          path = session["value"]
          match = path.is_a?(String) && SESSION_PATH.match(path)
          return nil unless match && path.bytesize <= 4096 && File.expand_path(path) == path
          {"path" => path, "session_id" => match[1], "terminal_id" => row["terminal_id"].to_s}
        end

        def foreground?(executor, pane, pid)
          json = executor.pane_process_info(pane).parsed_json
          info = json.is_a?(Hash) && json["result"].is_a?(Hash) ? json["result"]["process_info"] : nil
          list = info.is_a?(Hash) ? info["foreground_processes"] : nil
          list.is_a?(Array) && list.any? { |row| row.is_a?(Hash) && row["pid"] == pid }
        end

        def branch_for(content)
          lines = content.lines
          raise ArgumentError, "session entry limit" unless lines.size.between?(2, MAX_ENTRIES + 1)
          header = JSON.parse(lines.shift, create_additions: false, max_nesting: 64, allow_duplicate_key: false)
          raise ArgumentError, "invalid Pi session" unless header.is_a?(Hash) && header["type"] == "session" && header["version"] == 3
          entries = {}
          last = nil
          lines.each do |line|
            entry = JSON.parse(line, create_additions: false, max_nesting: 64, allow_duplicate_key: false)
            raise ArgumentError, "invalid session entry" unless entry.is_a?(Hash) && entry["id"].is_a?(String) &&
              !entry["id"].empty? && !entries.key?(entry["id"]) &&
              (entry["parentId"].nil? || entries.key?(entry["parentId"]))
            entries[entry["id"]] = entry
            last = entry
          end
          branch = []
          while last
            branch << last
            last = last["parentId"] && entries.fetch(last["parentId"])
          end
          [header, branch.reverse]
        end
      end
    end
  end
end
