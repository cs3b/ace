# Idea

Create ace-support-cli gem to replace dry-cli dependency. We have recurring issues with dry-cli: type coercion for --timeout (integers/floats passed as strings to Faraday), limited option validation, no built-in numeric coercion for type: :integer options. A custom ace-support-cli package could fix these systematically across all ace-* gems instead of patching each gem individually. Could mirror dry-cli API for easy migration.

---
Captured: 2026-02-28 01:33:39
