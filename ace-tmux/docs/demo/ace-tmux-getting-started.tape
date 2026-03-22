# Description: Showcase ace-tmux preset discovery, session start, and window management
# Tags: ace-tmux, docs, getting-started

Output docs/demo/ace-tmux-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Discover available presets (sessions, windows, panes)
Type "ace-tmux list"
Enter
Sleep 4s

# Scene 2: Start a session from a preset without attaching
Type "ace-tmux start default --detach"
Enter
Sleep 3s

# Scene 3: Add a window to the running session
Type "ace-tmux window cc --session default"
Enter
Sleep 3s

# Scene 4: Verify session is running with windows
Type "tmux list-windows -t default"
Enter
Sleep 4s
