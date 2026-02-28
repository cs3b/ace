---
status: done
priority: now
id: 8l1sss
title: Idea
tags: []
created_at: '2025-10-02 19:11:58'
---

# Idea

 We need to handle the api errors and have fallback model for llm-query and in higher level like ace-git-commit  ⏺ Bash(ace-git-commit -i 'Migrate idea and feature management workflows to ace-taskflow - completed task 047')
  ⎿  Error: /Users/mc/Ps/ace-meta/ace-git-commit/lib/ace/git_commit/molecules/message_generator.rb:38:in
     'Ace::GitCommit::Molecules::MessageGenerator#generate': Failed to generate commit message: google API error:
     Google API error (503): The model is overloaded. Please try again later. (Ace::GitCommit::Error)
        from /Users/mc/Ps/ace-meta/ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb:138:in
     'Ace::GitCommit::Organisms::CommitOrchestrator#generate_message'
        from /Users/mc/Ps/ace-meta/ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb:115:in
     'Ace::GitCommit::Organisms::CommitOrchestrator#get_commit_message'
        from /Users/mc/Ps/ace-meta/ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb:37:in
     'Ace::GitCommit::Organisms::CommitOrchestrator#execute'
        from /Users/mc/Ps/ace-meta/ace-git-commit/exe/ace-git-commit:22:in 'Ace::GitCommit::CLI#run'
        from /Users/mc/Ps/ace-meta/ace-git-commit/exe/ace-git-commit:12:in 'Ace::GitCommit::CLI.run'
        from /Users/mc/Ps/ace-meta/ace-git-commit/exe/ace-git-commit:105:in '<top (required)>'
        from /Users/mc/Ps/ace-meta/bin/ace-git-commit:17:in 'Kernel#load'
        from /Users/mc/Ps/ace-meta/bin/ace-git-commit:17:in '<main>'
     /Users/mc/Ps/ace-meta/ace-llm/lib/ace/llm/organisms/base_client.rb:173:in
     'Ace::LLM::Organisms::BaseClient#handle_api_error': google API error: Google API error (503): The model is
     overloaded. Please try again later. (Ace::LLM::ProviderError)
     … +23 lines (ctrl+o to see all)

---
Captured: 2025-10-02 20:12:30