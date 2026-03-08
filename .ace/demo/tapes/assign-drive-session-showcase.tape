# Description: Drive an existing assignment session and wait for completion
# Tags: assign, drive, delegation, fork

Output .ace-local/demo/assign-drive-session-showcase.gif

Set FontSize 14
Set Width 1200
Set Height 720
Set TypingSpeed 0ms

Type "ASSIGN_ID=$(basename $(readlink .ace-local/assign/.latest))"
Enter
Sleep 1s

Type "mise exec -- ace-assign status --assignment $ASSIGN_ID"
Enter
Sleep 8s

Type "claude --dangerously-skip-permissions -p '/as-assign-drive $ASSIGN_ID'"
Enter
Sleep 105s

Type "mise exec -- ace-assign status --assignment $ASSIGN_ID"
Enter
Sleep 16s
