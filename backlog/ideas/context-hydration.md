## tools - bin/context

  -> send prompt / workflow instruction and use (gemini flash lite to compact it) combine it in to single context document -> save as file for the task and return path
  -> use workflow instructions and load the context in single file (with summary on top)
  -> compact version on top and embed documents below with links to line numbers
  -> most of the code editors read 200 lines at once (summary in 200 lines, meybe use long lines and compact files in few lines)
  -> input: --prompt --file --task (in witch we will be using it, task is not embeded but it's use for interfering additional context)
  -> should also include tools call response (bin/tn | bin/gl) - it should be agent with tool calling capability
