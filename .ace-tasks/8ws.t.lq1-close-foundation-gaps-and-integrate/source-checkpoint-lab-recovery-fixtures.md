# Lab recovery fixture integration

Two test-only corrections follow the current original-control/recovery contract:

- 77cda9df2: cleanup dispatch context now includes the four canonical evidence fields required by the producer. Duplicate-key test still reaches actual input validation. Independent review by review_lab_bootstrap approved; exact file passed8/45 (lab/db3e2b98).
- dcd4fdbdb: a forged recovery mapping is rejected by original control reservation authentication before service-status authorization. Test now asserts exact EvidenceUnavailable/message and unchanged canonical ref. Independent review by wave_n0n approved; exact scenario passed1/31 in24.71s (lab/26bbbe01). Later corruption checks remain intact.

Product schemas, authorization order and error behavior were not weakened. Whole-package verification remains incomplete: all reportc73fd094 timed out organisms after159/605 successful earlier tests; per-file diagnostic19140989 independently timed out protected_cleanup_dispatch_test.rb and exposed the now-corrected recovery expectation. Diagnostic crossed a generic retirement integration and cannot prove one frozen revision. Root is measuring individual cleanup scenarios without increasing120s limits.
