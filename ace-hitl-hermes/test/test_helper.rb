# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/hitl/hermes"
require "fileutils"
require "stringio"

# Base test case for ace-hitl-hermes: real-temp-folder helpers and a
# deterministic clock for contract tests.
class AceHermesTestCase < AceTestCase
  QUESTION_TS = "2026-09-24T10:00:00Z"
  ANSWER_TS = "2026-09-24T10:05:00Z"

  def with_hermes_dir(name: "inbox")
    Dir.mktmpdir("ace-hitl-hermes") do |tmp|
      folder = File.join(tmp, name)
      FileUtils.mkdir_p(folder)
      yield folder
    end
  end

  # A registry + box over a real temp folder named `name`.
  def build_box(folder, name: File.basename(folder), machine: "lab01",
    notifier: nil, id_generator: -> { SecureRandom.hex(6) }, euid_provider: nil)
    registry = Ace::Hitl::Hermes::Molecules::HermesChannels::Registry.new
    registry.register(name, machine: machine, folder: folder)
    box = Ace::Hitl::Hermes::Organisms::HermesBox.new(
      channel: name, registry: registry,
      id_generator: id_generator,
      notifier: notifier,
      euid_provider: euid_provider || -> { Process.euid }
    )
    [box, registry]
  end

  def collector
    lines = []
    notifier = ->(line) { lines << line }
    [notifier, lines]
  end

  def write_file(path, content, mode: nil)
    File.write(path, content)
    File.chmod(mode, path) if mode
    path
  end

  def message_file(folder, id, payload_hash)
    write_file(
      File.join(folder, "#{id}.json"),
      JSON.generate(payload_hash)
    )
  end

  def question_payload(id: "q-1", question: "Proceed with deploy?", sender: "agent-7",
    created_at: QUESTION_TS)
    {
      "schema" => Ace::Hitl::Hermes::Molecules::HermesContract::MESSAGE_SCHEMA,
      "id" => id,
      "kind" => "question",
      "sender" => sender,
      "question" => question,
      "created_at" => created_at
    }
  end

  def answer_payload(id: "q-1", answer: "Ship it.", sender: "captain",
    received_at: ANSWER_TS)
    {
      "schema" => Ace::Hitl::Hermes::Molecules::HermesContract::MESSAGE_SCHEMA,
      "id" => id,
      "kind" => "answer",
      "sender" => sender,
      "answer" => answer,
      "received_at" => received_at
    }
  end

  def tmp_leftovers(folder)
    Dir.children(folder).select { |n| n.start_with?(".hermes-tmp-") }
  end
end
