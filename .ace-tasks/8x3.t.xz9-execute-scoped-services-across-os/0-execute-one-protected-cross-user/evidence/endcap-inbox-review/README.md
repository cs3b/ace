# Independent source review evidence

Original failed regressions are deliberately retained beside corrected passes.
The two Ruby fixtures are verbatim reviewer scratch files, preserved as source
provenance. Their original location is `.ace-local/review/` in the isolated review
checkout; restore there before reproducing the commands recorded in the review
reports. They are not installed/package tests or proof of native Lab behavior.

Consumer943444 and shared core07ee62443 have independent bounded approvals.
Final package/default-suite verification and main integration are still pending
at the time these review artifacts were retained. An interrupted initial full
Assign run on ec57 returned130 and produced no final report; its completed fast
phase is not a full-package pass.
