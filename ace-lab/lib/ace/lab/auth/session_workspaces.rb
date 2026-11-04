# frozen_string_literal: true
require_relative "session_configuration"
require_relative "session_native_transport"

module Ace::Lab::Auth
  # Herdr remains the workspace owner. The issuer only narrows the existing
  # workspace API to configured projects granted to the calling supervisor.
  class SessionWorkspaces
    METHODS = %w[workspace.list workspace.create].freeze
    FIELDS = %w[workspace_id label focused pane_count tab_count active_tab_id agent_status number].freeze

    def initialize(loader: -> { Ace::Lab::Molecules::InstallManifestLoader.load }, transport: SessionNativeTransport.new)
      @loader, @transport = loader, transport
    end

    def call(request, identity:)
      self.class.validate!(request)
      unless %w[lab-overseer project-overseer].include?(identity.role)
        raise Refusal, "only supervisors can manage project workspaces"
      end
      document = @loader.call
      configuration = SessionConfiguration.new(loader: -> { document })
      selections = document.fetch("projects").filter_map do |project|
        begin
          configuration.resolve(project: project.fetch("id"), role: "worker", session: identity)
        rescue Error
          nil
        end
      end
      id = request.fetch("id")
      if request["method"] == "workspace.list"
        result = native(id, "workspace.list", {}, identity)
        rows = result.fetch("workspaces").select { |row| selections.any? { |entry| entry.project == row["label"] } }
        return {"id" => id, "result" => {"type" => "workspace_list", "workspaces" => rows.map { |row| project(row) }}}
      end
      params = request.fetch("params")
      selection = selections.find { |entry| entry.project == params.fetch("label") }
      raise Refusal, "workspace project is not granted" unless selection
      if params["cwd"] && params["cwd"] != selection.path
        raise Refusal, "workspace directory differs from configured project"
      end
      # Runtime and shell environment are never supplied by the session.
      result = native(id, "workspace.create", {"label" => selection.project, "cwd" => selection.path, "focus" => false}, identity)
      workspace = result.fetch("workspace")
      unless workspace["label"] == selection.project && workspace["workspace_id"].is_a?(String)
        raise Error, "workspace creation identity differs"
      end
      {"id" => id, "result" => {"type" => "workspace_created", "workspace" => project(workspace)}}
    rescue KeyError, TypeError, NoMethodError
      raise Error, "workspace response is incomplete"
    end

    def self.validate!(request)
      unless request.is_a?(Hash) && request.keys.sort == %w[id method params] && METHODS.include?(request["method"]) &&
          request["id"].is_a?(String) && request["id"].bytesize.between?(1, 512) && !request["id"].match?(/[[:cntrl:]]/) &&
          request["params"].is_a?(Hash)
        raise Error, "invalid workspace request"
      end
      params = request.fetch("params")
      if request["method"] == "workspace.list"
        raise Error, "invalid workspace list fields" unless params.empty?
      else
        unless (params.keys - %w[label cwd focus]).empty? && params["label"].is_a?(String) &&
            params["label"].match?(/\A[a-z][a-z0-9_-]{0,31}\z/) &&
            (!params.key?("focus") || params["focus"] == false) &&
            (!params.key?("cwd") || (params["cwd"].is_a?(String) && params["cwd"].start_with?("/")))
          raise Error, "invalid configured workspace creation"
        end
      end
      true
    end

    private

    def project(row) = row.select { |key, _| FIELDS.include?(key) }

    def native(id, method, params, identity)
      response = @transport.call({"id" => id, "method" => method, "params" => params}, identity: identity)
      raise Error, "workspace operation failed" if response.key?("error")
      response.fetch("result")
    end
  end
end
