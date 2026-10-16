# frozen_string_literal: true
module Ace
  module Design
    module Molecules
      module AdjustPrompts
        SYSTEM = <<~TEXT.freeze
          Compose project design assumptions, not application code. Work only in this supplied workspace.
          Do not inspect the repository, install tools, browse, run audits, or modify input files.
          User decisions override library style defaults. Preserve their intent, including exceptions.
          Never weaken execution permissions, artifact requirements or shared-data contracts.
          Do not silently invent a resolution for ambiguous user decisions: report a conflict instead.
        TEXT
        PROMPT = <<~TEXT.freeze
          Read request.json. It contains ordered contexts (parents before children), their old/new
          defaults, exact user decision history, previous generated design, and parent identity.
          Fresh ancestors are omitted; parent_design supplies their unchanged effective assumptions.
          Write result.json with exactly two top-level keys: "contexts" and "conflicts".
          "conflicts" is an array of strings naming unresolved ambiguity and the question to resolve it.
          "contexts" maps EVERY supplied context ID (including "" for project) to:
          {"design":"Complete effective Markdown assumptions", "added_rules":["..."],
           "preserved_exceptions":["..."], "omitted_defaults":["..."]}.
          Use STRING values for design and arrays of STRINGS for each summary field; no other schema.
          Process parents first. A child's design inherits its parent's NEW effective design,
          then refines it with its own new defaults and user decisions. Read and reuse the parent's
          result you just composed, or parent_design when that parent is absent from this request.
          Never inherit an obsolete previous design. All inherited user decisions
          remain authoritative. Later explicit user decisions can supersede earlier decisions;
          otherwise preserve them. A clear user preference overriding a library default is not a conflict.
          Reconcile additions/removals/changes in library defaults against old defaults and user intent.
          Do not retain removed defaults merely because they appeared in the old generated text.
          Keep each effective design concise (roughly 250 words), useful for the task, with concrete rules.
          Distinguish views (hierarchy, navigation, tasks) from components (API of interaction, states,
          keyboard/focus, container behavior). Avoid universal aesthetic bans.
          Do not duplicate the verbatim user ledger in design: the CLI appends it authoritatively.
          Do not write user.md/defaults.md or any project files. Write result.json only.
        TEXT
      end
    end
  end
end
