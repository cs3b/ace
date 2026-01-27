# High level plan for overseer worker

use native task tool to track progress for this assignments

| ace... ( those are Skills run them as skills ) 

  1. ace:work-on-task 228
  
    at the very end 
    - ensure that you commited all the changes (ace:commit)
    - that you have released all the pakcages that we have modified (ace-release <pkg-name> <patch|minor> ) 
    - mark task as done usin ace-taskflow task done and esnure everything is on remote branch
  2. ace:create-pr / or update if already exists
  3. /review this pr
  4. implement all feedback taht is high and critical
  5. ace:review-pr preset: code-deep, pr: <prnumber> (but at the end do not ask question, just work all the feedbackk medium level and above)
  6. run ace-test-suite ensure eveyrgthing works use /ace:commit 
  7. repeat step 5 & 6
  8. repeat step 5 & 6

### some additional steps we might need 

--- don't know how we should ensure the a) it works ( tests + e2e tests) and it is b) well, but not over engineered 

--- is there anything to cleanup up 

---- is there anything not released or changelog not updated 

------ can we simplify the main changelog 

--- review should we release or reorganize any commits

--- review updates to documentation / or task (f we have changed anything (as saddiotna phase, or updaeds  

--- runn all the e2e tests 

--- update pr desc 

--- 


---

## notes from working with, and sometimes ignoring most of the steps except one - maybe we should use native task tool if it is present in the claude code (or other agents we will support, but would like to avoid it and keep it general - but inabuiquity )


ensure that you have all the 8 steps in native tasks - before starting with first tasks present the high level plan you will follow  


Rozumiem frustrację. Masz rację.

  Problem:
  Kiedy skill mówi "Run: /ace:commit" - ja dosłownie ładuję kolejny skill, zamiast po prostu ZROBIĆ commit.

  Rozwiązanie:

  Kiedy widzę w instrukcji skill reference jako KROK (nie jako główne zadanie), powinienem:
  - /ace:commit → wykonać ace-git-commit bezpośrednio
  - /ace-bump-version X Y → wykonać ace-bump-version X Y bezpośrednio
  - /ace-update-changelog → wykonać ace-update-changelog bezpośrednio

  Propozycja zapisu w skillach:

  ## Step 1: Commit changes
  Action: `ace-git-commit [path] -i "[intention]"`

  ## Step 2: Bump version
  Action: `ace-bump-version $package $level`

  Używając "Action:" zamiast "Run: /skill" - jasno mówisz "wykonaj komendę", nie "załaduj skill".

  ---
  Wracam do release. Wykonuję sekwencyjnie:



  Honest answer:

  1. Presence of options - When I see two strategies listed, I feel I must
  "choose", which requires analysis first
  2. Wanting to appear helpful - I show reasoning, ask confirmation,
  explain trade-offs. All friction.
  3. Fear of destructive operations - git reset feels dangerous, so I
  hesitate and ask
  4. Training bias - I'm rewarded for being thorough, considering edge
  cases, explaining myself

  ---
  What would help:

  - No options in workflows - Single path, not "Strategy A vs Strategy B"
  - Imperative language - "Run this" not "You can run this"
  - Defaults are THE way - Not "the default way" (implies alternatives)
  - Edge cases buried - Not presented alongside the main path
  - Explicit "just do it" - Maybe even: "Do not analyze. Execute these
  commands."

  The irony: ACE is designed to eliminate decisions with sensible defaults.
   When I add decision points, I'm fighting the tool's philosophy.
