fix(component): resolve issue with data handling

Root cause: Incorrect null check in process method
Solution: Add proper validation before processing

- Fix null pointer exception
- Add test cases for edge scenarios
- Update error messages

Fixes #bug-id
