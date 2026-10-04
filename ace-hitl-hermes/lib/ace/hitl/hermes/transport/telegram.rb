# frozen_string_literal: true

require "faraday"
require "json"

module Ace
  module Hitl
    module Hermes
      module Transport
        # No retry middleware: sendMessage is not idempotent. A lost response
        # must become uncertain instead of silently sending a second request.
        class Telegram
          def initialize(token_file:, connection: nil)
            stat = File.lstat(token_file)
            unless stat.file? && !stat.symlink? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
              raise ContractError, "Telegram token file must be owned and private"
            end
            token = File.read(token_file).strip
            unless token.match?(/\A\d+:[A-Za-z0-9_-]+\z/)
              raise ContractError, "Telegram token file is invalid"
            end
            @connection = connection || Faraday.new(url: "https://api.telegram.org/bot#{token}/") do |http|
              http.options.open_timeout = 10
              http.options.timeout = 35
            end
          end

          def call(channel, question)
            value = request("sendMessage", {"chat_id" => channel["chat_id"], "text" => question})
            {"success" => true, "chat_id" => value.fetch("chat").fetch("id").to_s,
             "message_id" => value.fetch("message_id").to_s}
          end

          def updates(offset:)
            result = request("getUpdates", {"offset" => offset, "timeout" => 20, "limit" => 100,
                                             "allowed_updates" => ["message"]})
            raise ContractError, "Telegram returned malformed updates" unless result.is_a?(Array)
            result
          end

          private

          def request(method, params)
            response = @connection.post(method) do |req|
              req.headers["Content-Type"] = "application/json"
              req.body = JSON.generate(params)
            end
            envelope = JSON.parse(response.body)
            unless envelope.is_a?(Hash) && envelope["ok"] == true && response.status == 200
              raise SubmitFailed, "Telegram refused submission" if method == "sendMessage" && response.status < 500
              raise ContractError, "Telegram polling failed"
            end
            envelope.fetch("result")
          rescue JSON::ParserError, KeyError, Faraday::Error
            raise ContractError, "Telegram response unavailable or malformed"
          end
        end
      end
    end
  end
end
