# R4 cleanup regression diagnosis

The old process-group cleanup reproduces two detached-child leaks. The new
subreaper candidate does not pass: an empty procfs child inventory returns nil
from bounded File#read, causing NoMethodError before launch. Its six failures and
the related domain composition failure are retained here, not counted as acceptance.

The fixture owns and reaps its deliberately detached children. Production owner
PID554643 remains unchanged. Fix and rerun use a fresh immutable R5 export.

Independent configured Pi review of the original command slice is retained in
../source-review-command; it approved that source but identified detached-child
cleanup and effective-root refusal as follow-ups. That approval does not cover the
new cleanup implementation.
