# Description: Prepare a batch assignment and wait for skill response
# Tags: assign, prepare, delegation, batches

Output .ace-local/demo/assign-prepare-showcase.gif

Set FontSize 14
Set Width 1200
Set Height 720
Set TypingSpeed 0ms

Type "claude --dangerously-skip-permissions -p '/as-assign-run-in-batches Run-quick-read-only-check-for-{{item}} --items alpha,beta,gamma,delta,epsilon --max-parallel 2'"
Enter
Sleep 75s

Type "ASSIGN_ID=$(basename $(readlink .ace-local/assign/.latest))"
Enter
Sleep 1s

Type "echo $ASSIGN_ID"
Enter
Sleep 2s

Type "mise exec -- ace-assign status --assignment $ASSIGN_ID"
Enter
Sleep 16s
