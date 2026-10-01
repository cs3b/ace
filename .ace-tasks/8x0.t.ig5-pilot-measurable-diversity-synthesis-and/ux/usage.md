# Diversity pilot -- Draft Usage

## API Surface

Assignment workflows, role configuration and artifact/status contracts. Child tasks own the concrete interfaces; no second Lab execution engine is introduced.

## Scenario 1: Inspect the pilot before execution

**Action:** Supply three fresh task contracts and configured role bindings to benchmark preflight.

**Expected:** Nine planned task/arm cells and missing prerequisites are displayed without model calls. The pipeline distinguishes discovery, synthesis, final delivery and blind evaluation.

## Scenario 2: Preserve an incomplete outcome

**Action:** A required model is unavailable or a candidate fails acceptance.

**Expected:** The cell remains blocked/failed with provenance and known costs. No silent model-family replacement, fabricated success or automatic default-routing change occurs.

## Scenario 3: Resume from artifacts

**Action:** Hand completed discovery/synthesis artifacts to a fresh authorized context.

**Expected:** The same attempts, contracts and evidence are recovered without chat history; accepted history and independent review requirements remain intact.
