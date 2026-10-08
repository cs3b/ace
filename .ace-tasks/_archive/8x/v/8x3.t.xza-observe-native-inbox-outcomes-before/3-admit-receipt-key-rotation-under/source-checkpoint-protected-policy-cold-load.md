# Protected policy cold-load checkpoint

Parent: `21b0b6f83` Herdr error prerequisite; base before that `331ddef96`.

The actual Lab cleanup producer constructs ProtectedServicePolicy using its default trusted-document loader. That policy previously required broad `ace/assign` and implicitly relied on broad Lab loading for errors, the fixed authorization path and policy dependencies. The protected listener transitively reaches the same policy.

The existing Lab error definitions and fixed authorization constant/method are moved into explicit source owners, used by the broad entry and narrow policy alike. ProtectedServicePolicy requires only the Assign EvidenceDigest atom and its actual Lab dependencies. GrantResolver explicitly requires Date and Lab errors; ServicePolicy requires Lab errors. Authorization path, ownership traversal, policy, grants, transport and admission behavior are unchanged. No RubyGems/config exemption or Lab-defined foreign constants.

## Executed evidence

- Before repair fresh child policy load: `lab/ca7f03e0-68d3-4a30-b0f2-d47b3e4e6fb6`, 1/1 FAIL (`broad entry loaded`).
- Final fresh policy/listener children plus existing protected-policy tests: `lab/08c02fe4-df4d-42c3-926b-1ffc943b59dd`, 8/48 PASS, seed15627. Children use gems/rubyopt disabled and explicit load paths, reject broad Assign/Lab/Herdr/config loading, parse bound structured input, construct the actual default loader and verify its fixed path and fail-closed empty grants through a controlled read seam. No real authorization file is read by the children.
- Existing GrantResolver and ServicePolicy tests: `lab/3a1daaa4-ce87-4762-8c74-b57599c751de`, 18/58 PASS. Controlled traversal/stat/read seams and temporary files verify existing ownership/error/grant rules; no installation or native lifecycle probes.
- Intermediate `lab/a2355333-9570-4a2e-8e55-d1f421f2b8f8` retained FAIL because new test supplied raw target instead of existing ServiceInput.target projection; test corrected to use the actual owner projection, no production validation relaxed.

Raw reports retained in this worktree `.ace-local/test/reports`. This verifies loading and existing bounded policy behavior, not physical Installer/native acceptance. Independent reviewer and actual composed Installer proof remain required.

## Independent review repair

The independent reviewer identified ServicePolicy's rescue dependency on `Ace::Assign::Error`, which the narrowed graph did not require. The actual ServicePolicy owner now explicitly requires `ace/assign/errors`; no broad entrypoint is restored. The fresh policy/listener child also invokes a refusing canonical proposal resolver and requires the existing SecurityError classification. Before correction `lab/a37a2cd1-4462-43e1-b1fa-fe7c91bc99b4` reproduces NameError; final fresh load plus ProtectedServicePolicy/ServicePolicy tests `lab/c5f7319d-b0e3-4eb7-b468-a6057f1243b8` PASS12/67. This successor remains awaiting independent review.
