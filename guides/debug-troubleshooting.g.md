# High-Level Troubleshooting Workflow

This guide provides a general, technology-agnostic workflow for approaching development challenges, from initial
debugging to seeking help.

## Universal Troubleshooting Steps

| Step | What to do | Why |
|------|------------|-----|
| **1  Understand the system** | Skim docs/architecture first | You can’t debug what you don’t grasp. |
| **2  Make it fail on demand** | Reproduce the bug and minimise the input or scenario | Gives you a quick feedback loop & future test. |
| **3  Collect evidence** | Read stack traces, logs, error codes | Surface clues without touching code. |
| **4  Check recent changes/config** | Roll back toggles, feature flags, deployments | Regressions are usually fresh. |
| **5  Divide & conquer** | Bisect the call‑graph, comment blocks, or binary‑search commits | Narrows the suspect area fast. |
| **6  Form a hypothesis & probe** | Insert breakpoints/print‑debug, **do not "fix" yet** | Prevents cargo‑cult patches. |
| **7  Change one thing, re‑test** | One variable at a time, audit the steps | Keeps cause‑and‑effect clear. |
| **8  Validate & regress‑test** | Run the original minimal case + full suite | Confirms the root cause, avoids side‑effects. |
| **9  Document & share** | Note root cause, fix, follow‑ups | Future devs (and you) will thank you. |
| **10  Escalate or rubber‑duck** | Fresh eyes or an AI agent when stuck | External perspective breaks tunnel vision. |

## Elaborations on Key Steps

* **Step 2: Make it fail on demand:** This is crucial for effective testing. Aim for the *simplest possible*
  reproducible case. This often forms the basis of a new regression test (see Step 8).
* **Step 3 & 4: Collect evidence & Check recent changes:** Don't underestimate logs, configuration files, and
  recent commits (`git log`, `git blame`). Many issues are regressions introduced by recent changes.
* **Step 8: Validate & Regress-Test:** After applying a fix, *always* run the minimal failing case you created in
  Step 2 to confirm the specific issue is resolved. Then, run the broader test suite (e.g., `bin/rspec`, `npm test`)
  to check for unintended side-effects. Refer to the [Testing Guidelines Guide](testing.g.md) for more details.
* **Step 10: Escalate or Rubber Duck:** If you're stuck after diligently following the steps:
  * **Rubber Ducking:** Explain the problem out loud (to yourself, a pet, or an inanimate object). This often
    clarifies your thinking.
  * **AI Assistance:** Consult an AI agent. Use structured prompts, providing the context (code, error, steps taken).
    Reference the `[ask-an-agent workflow - PATH NEEDED]` for best practices.
  * **Human Escalation:** If AI doesn't help, reach out to teammates. Prepare by summarizing the problem, what
    you've tried (Steps 1-9), and specific questions. Check the `CONTRIBUTING.md` or team documentation for
    preferred communication channels.

## Utilizing Documentation and Research

* **Internal Docs:** Before extensive debugging, always check project-specific documentation (`README.md`,
  architecture diagrams in `docs-project/`, specific guides in `docs-dev/guides/`).
* **External Research:** Use search engines effectively. Formulate precise queries including error messages,
  technology names, and library versions.

## Language-Specific Considerations

While this guide provides a universal workflow, specific tools and techniques vary by language. For detailed
guidance, refer to the language-specific troubleshooting sections:

* [Ruby Troubleshooting](troubleshooting/ruby.md) (*To be created/moved from research*)
* [Rust Troubleshooting](troubleshooting/rust.md) (*To be created/moved from research*)
* [TypeScript Troubleshooting](troubleshooting/typescript.md) (*To be created/moved from research*)
