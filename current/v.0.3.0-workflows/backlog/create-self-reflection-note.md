1. The current conversations is the input for the analyze

2. Review how following instructions goes on, and identified

- what was a challange (multiple attempt to get to the results)
- when and why the user input was required
- when user input correct the work done
- when the tool result was big, or even truncated (polluting the token limit)

3. Next think about all of them from point 2. and group by challange, sort by higher impact first

4. Take Each group idetified in step 3. and think and proposed possible way(s) to improve it

5. Create file paths in
Directory:

- current release (use tool `bin/rc`) and find directory reflections inside this release folder
Filename:
- use tool call `now` to get current date
- with filename that have format <YYYYMMDD>-<HHMMSS>-<essence-of-the-session>.md
Full Path Example:
- dev-taskflow/current/v.0.2.0-synapse/reflections/20250621-124625-start-work-on-task.38.md)

6. Save The results from step 4 and save it into path identified in point 5.
