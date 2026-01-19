# Proposal: Add Local User Database

**Status:** Draft  
**Created:** 2026-01-19  
**Change ID:** `add-local-user-database`

## Problem Statement

The game currently lacks user authentication and account management capabilities. Before implementing Firebase Authentication, we need a temporary local database solution to:
- Enable user registration with username, password, and email
- Prevent duplicate accounts (same username or email)
- Support user login/authentication
- Track the currently logged-in user
- Validate user input (email format, username length)

This local implementation will serve as a placeholder that can be easily replaced with Firebase Auth while maintaining the same API surface.

## Proposed Solution

Create a global `UserDatabase` autoload script that provides in-memory user storage and authentication. The API will mirror Firebase Auth patterns to minimize refactoring effort when switching to the real backend.

### Key Features
1. **User Registration**: Create new user accounts with username, password (hashed), and email
2. **Duplicate Detection**: Check for existing usernames and emails before registration
3. **Input Validation**: 
   - Email must contain `@` and valid TLD (.com, .de, .org, .net, etc.)
   - Username must be 5-15 characters
   - No password requirements (length/complexity)
4. **Authentication**: Sign in with username/password
5. **Session Management**: Track currently logged-in user
6. **Firebase-Style API**: Methods and error codes that match Firebase Auth conventions
7. **Password Security**: Hash passwords using SHA-256 (even for temporary storage)

### Design Decisions
- **In-memory only**: No file persistence (data cleared when game closes)
- **Simple implementation**: Minimal complexity, easy to understand and replace
- **Firebase-compatible**: API designed to match Firebase Auth methods and error codes
- **Password hashing**: Use Godot's built-in crypto functions to hash passwords (matches Firebase security practices)

## Affected Capabilities

### New Capabilities
- **local-user-database**: Global user database service for registration, authentication, and session management

### Modified Capabilities
None (new functionality)

## Migration Path

When switching to Firebase Auth:
1. Replace `UserDatabase` autoload with `FirebaseAuth` wrapper
2. Update method implementations to call Firebase SDK
3. Keep the same method signatures and error codes
4. Remove password hashing (Firebase handles this internally)

## Risks & Considerations

- **No persistence**: Users must re-register each session (acceptable for development/testing)
- **Limited security**: In-memory storage is not secure for production (by design)
- **No password recovery**: Cannot reset forgotten passwords (out of scope for temporary solution)
- **Single-device only**: No synchronization across devices (expected limitation)

## Success Criteria

- [x] User can register with valid username, email, and password
- [x] System prevents duplicate usernames and emails
- [x] System validates email format and username length
- [x] User can log in with correct credentials
- [x] System rejects invalid credentials
- [x] Current user session is tracked globally
- [x] Error codes match Firebase Auth patterns
- [x] API is easy to replace with Firebase implementation

## References

- Firebase Auth Documentation: https://firebase.google.com/docs/auth
- Godot Crypto Class: https://docs.godotengine.org/en/stable/classes/class_crypto.html
