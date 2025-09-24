# Reflections Template

## Stop Doing

- Allowing stdout leakage in unit tests - this makes test output noisy and harder to debug
- Writing integration tests that don't properly use VCR for recording HTTP interactions
- Using inconsistent parameter handling between CLI arguments and method calls (mixing hash vs keyword arguments)
- Relying on `exit` calls in CLI commands without proper testing patterns that handle SystemExit exceptions

## Continue Doing

- Using comprehensive VCR cassettes that include both health check and actual API calls for realistic integration testing
- Following the ATOM architecture pattern (organisms composing molecules) for consistent code organization
- Writing detailed unit tests with proper mocking to isolate components and test error scenarios
- Using Aruba for CLI integration testing to properly test the executable behavior

## Start Doing

- Capturing stdout/stderr output in all tests that involve print statements to prevent leakage
- Using SystemExit exceptions in tests when mocking exit calls to ensure proper test flow control
- Adding explicit parameter validation and type checking in CLI command methods
- Creating more comprehensive error handling scenarios in integration tests using WebMock for server unavailability
- Ensuring VCR cassettes include all necessary HTTP interactions (both GET /models and POST /chat/completions)