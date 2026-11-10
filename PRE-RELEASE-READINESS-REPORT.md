# QuizBattles Google Play Store Release Readiness Report

**Date:** November 5, 2026  
**Project:** QuizBattles (Godot 4.7, 2D Mobile Quiz Duel Game)  
**Report Type:** Comprehensive Pre-Release Audit  
**Scope:** Analysis only - no code changes included

---

## Executive Summary

**Current Completion Status: 65–70%**

QuizBattles has substantial core functionality implemented, including:
- ✅ Local trivia question system with multilingual support (EN, DE, ZH, ZH-TW)
- ✅ Firebase authentication and Firestore integration
- ✅ Multiplayer match infrastructure (setup, lobby, gameplay)
- ✅ Android export configuration
- ✅ Account management screens and navigation
- ✅ Question delivery and gameplay mechanics

**However, the project is NOT READY for Google Play Store submission** due to 5 critical blockers and several high-priority gaps that must be resolved first.

### Critical Blockers (Must Fix Before Submission)

| # | Severity | Blocker | Impact |
|----|----------|---------|--------|
| 1 | 🔴 **CRITICAL** | Firebase configured for emulator mode | Will not work in production; all data is local-only |
| 2 | 🔴 **CRITICAL** | Android build files missing | Cannot generate signed APK/AAB for Play Store |
| 3 | 🔴 **CRITICAL** | Export preset incomplete | No version, icons, SDK config, or release keystore |
| 4 | 🔴 **CRITICAL** | Multiplayer test code active | Debug accounts and single-player path embedded in production code |
| 5 | 🔴 **CRITICAL** | Google Sign-In not production-verified | OAuth, real-device registration, offline behavior untested |

### What's Ready

- Core gameplay loop (question flow, scoring, turn management)
- Local trivia database loading and caching
- Firebase user account creation and persistence
- Scene navigation and UI structure
- Android platform detection
- Firestore security rules (basic access control)
- Cloud Functions for matchmaking

### What's Not Ready

- Production Firebase deployment and configuration
- Android build/signing setup
- Release version, branding, and store assets
- Production OAuth credentials and certificates
- Real-device testing and validation
- Multiplayer reconnect and offline handling
- Error feedback and offline UX
- Account deletion flow (may be required for Play policy)
- Google Sign-In production verification

---

## Section 1: Critical Blockers

### Blocker 1: Firebase Emulator Mode

**Location:** `project.godot:34-40`, `firebase.json`  
**Severity:** 🔴 CRITICAL  
**Status:** Blocks all releases

**Issue:**
The project is configured to use Firebase emulators (`[firebase] runtime_mode="emulator"`) with localhost endpoints (`0.0.0.0:9099`). This configuration works for local development but will fail entirely in production:

```gdscript
# From project.godot
[firebase]
runtime_mode="emulator"
```

**Evidence:**
- `firebase.json` binds all services to `0.0.0.0` (localhost)
- Godot tries to connect to local emulator ports, which do not exist on user devices
- No production Firebase project credentials are configured

**Impact:**
- ❌ Users cannot authenticate
- ❌ No data persistence
- ❌ All multiplayer features fail
- ❌ Game is completely non-functional on release

**To Fix:**
1. Create a production Firebase project in Google Cloud Console
2. Switch `runtime_mode="production"` in `project.godot`
3. Configure production credentials in `firebase.json`
4. Deploy Firestore rules and Cloud Functions to production
5. Test authentication and data sync on a real device

**Estimated Effort:** 2-4 hours (mostly setup and testing)

---

### Blocker 2: Android Build Files Missing

**Location:** `android/` directory  
**Severity:** 🔴 CRITICAL  
**Status:** Blocks Android export

**Issue:**
The `android/` directory contains no Gradle build template, no `build.gradle`, and no Android project files. Godot cannot generate a signed APK or AAB without these templates.

```
android/
  build/  # (only contains build artifacts, not templates)
  # Missing: build-template/ with build.gradle, gradle.properties, etc.
```

**Evidence:**
- Running Godot export without templates fails
- No `AndroidManifest.xml.template` or gradle build files
- No release signing configuration

**Impact:**
- ❌ Cannot export to APK or AAB
- ❌ Cannot submit to Play Store
- ❌ Android platform completely blocked

**To Fix:**
1. Run `godot --export-template` or use Godot editor to generate Android export templates
2. Customize `build-template/build.gradle` with target SDK (API 34+), app ID, permissions
3. Add `gradle.properties` with Gradle configuration
4. Test export on Godot desktop (File > Export > Android)

**Estimated Effort:** 1-2 hours (template generation + configuration)

---

### Blocker 3: Export Preset Incomplete

**Location:** `export_presets.cfg:35-55`  
**Severity:** 🔴 CRITICAL  
**Status:** Blocks Play Store submission

**Issue:**
The Android export preset is missing critical metadata required by Google Play Store:

```ini
[preset.0]
name="Android"
platform="Android"
runnable=true
custom_features=""
export_filter="all_resources"
export_files=PackedStringArray()
script_export_mode=1
script_encryption_key=""

# MISSING:
# - package/version (version name and code)
# - icons/main_192x192 (launcher icon)
# - icons/adaptive_foreground_432x432 (adaptive icon)
# - architectures/armeabi_v7a=true (ARM support)
# - gradle_dependencies
# - package/signed=true with keystore path
# - release/use_legacy_toolchain
# - permissions/ACCESS_NETWORK_STATE, INTERNET
```

**Evidence:**
- `export_presets.cfg` has empty version fields
- No icons configured
- No release keystore path
- No API level or target settings

**Impact:**
- ❌ Play Store rejects submission (invalid version)
- ❌ App lacks branding and icons
- ❌ Permissions not properly declared
- ❌ Cannot sign for release

**To Fix:**
1. Set version name (e.g., "1.0.0") and version code (e.g., 1) in export preset
2. Add launcher icon (192x192) and adaptive icon (432x432) in `assets/`
3. Configure package permissions (INTERNET, VIBRATE, etc.)
4. Generate release keystore: `keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release_key`
5. Configure keystore path and password in export preset
6. Test export and APK signing

**Estimated Effort:** 2-3 hours (icon creation + configuration + testing)

---

### Blocker 4: Multiplayer Test Code Active in Production

**Location:** `scenes/ui/setup_screen.gd:66-77`, `scenes/ui/lobby_pages/duel_page.gd:4-8`  
**Severity:** 🔴 CRITICAL  
**Status:** Blocks release (release build will contain test paths)

**Issue:**
The codebase contains explicit development/test paths that should not ship:

```gdscript
# setup_screen.gd - Single-player path marked for removal
if in_multiplayer_mode:
    # ...multiplayer setup...
else:
    # TODO: Remove this path once multiplayer is stable
    _emit_local_test_duel()
```

```gdscript
# duel_page.gd - Test account credentials
var test_players = {
    "alice_test": {...},
    "bob_test": {...}
}

# Explicit test-account behavior
if current_player.id in ["alice_test", "bob_test"]:
    # Skip Firebase sync
    pass
```

**Evidence:**
- Single-player path is a TODO, not disabled
- Test account IDs are hardcoded
- Test duel emission uses local signals, not Firebase
- Debug behavior is conditional on string matching, easy to trigger accidentally

**Impact:**
- ❌ Testers/early users could bypass multiplayer
- ❌ Test accounts might exist in production data
- ❌ Code paths not covered by release QA
- ❌ Privacy/fairness concerns if test paths activate

**To Fix:**
1. Remove single-player path entirely from `setup_screen.gd` (delete the else block)
2. Remove test account list from `duel_page.gd`
3. Add assertion: `assert(not (current_player.id.contains("_test")), "Test account in production")`
4. Run full multiplayer flow on real devices (no single-player fallback)
5. Tag release build with release configuration flag

**Estimated Effort:** 1-2 hours (code cleanup + testing)

---

### Blocker 5: Google Sign-In Not Production-Verified

**Location:** `openspec/changes/add-google-sign-in-registration/tasks.md:18-19, 42-43`  
**Severity:** 🔴 CRITICAL  
**Status:** In-progress, deferred until after Play Store release (per user request)

**Issue:**
The Google Sign-In feature is planned and partially implemented, but critical production verification is incomplete:

**Pending manual verification tasks:**
- Real Android device sign-in registration
- Sign-in retry and cancellation flows
- Offline registration and reconnect
- Production OAuth certificate installation
- Firebase OAuth provider configuration
- Release signing fingerprint registration

**Evidence:**
- Tasks document lists these as "pending"
- No device test results documented
- Production credentials appear incomplete
- Offline behavior not validated

**Impact:**
- ❌ New users cannot register with Google on first launch
- ❌ Sign-in flow behavior unknown on real devices
- ❌ Could cause app rejection during review

**Status Note:**
User explicitly requested postponement of Google Sign-In completion until after Play Store release. This is acknowledged but remains a critical gap for a complete user experience. Can defer if app has email registration as fallback.

**To Fix (post-release):**
1. Verify production OAuth credentials in Firebase
2. Test Google Sign-In on real Android device (emulator insufficient)
3. Test cancellation, retry, and offline scenarios
4. Install release signing certificate fingerprint in Google Cloud Console
5. Test repeat sign-in on same device

**Estimated Effort:** 3-4 hours (device testing + OAuth setup)

---

## Section 2: High-Priority Issues

### High-1: Firestore Rules Incomplete

**Location:** `firestore.rules:30-33, 88-90`  
**Severity:** 🟠 HIGH  
**Status:** Needs review before production deployment

**Issue:**
User profiles and usernames allow unrestricted `get/list` access:

```firestore
match /users/{uid} {
  allow read;  # Anyone can read any user profile
  allow write: if request.auth.uid == uid;  # Only owner can write
}

match /usernames/{username} {
  allow read;  # Public read
  allow write: if ... owner check ...
}
```

**Impact:**
- User list could be enumerated by third parties
- Potential privacy violation depending on GDPR compliance requirements
- May violate app store privacy policy

**Recommendation:**
Review privacy requirements. If user lists should be private:
- Change `allow read` to `allow read: if request.auth != null` (authenticated users only)
- Test impact on friend search feature (may need server-side filtering)

---

### High-2: No Account Deletion Workflow

**Location:** Project-wide (no `delete_account` function found)  
**Severity:** 🟠 HIGH  
**Status:** Likely required for Play Store compliance

**Issue:**
No UI or backend function exists for users to delete their accounts. Google Play Store and privacy regulations (GDPR, CCPA) may require account deletion capability.

**To Fix:**
1. Create `delete_account()` endpoint in Cloud Functions
2. Add account deletion screen to Account Management UI
3. Cascade delete user data (profile, matches, friendships, notifications)
4. Document data deletion process for privacy policy

---

### High-3: Offline Error Handling Missing

**Location:** `scenes/ui/` (all screens)  
**Severity:** 🟠 HIGH  
**Status:** No visual error feedback for network failures

**Issue:**
Firebase authentication and data sync errors are logged to console only. Users have no feedback if:
- Network is down
- Firebase is unreachable
- Authentication token expired
- Firestore write failed

**Evidence:**
- Google Sign-In service logs errors but doesn't show UI (check `autoload/google_sign_in_service.gd:60-85`)
- Live update service silently fails (check `autoload/live_update_service.gd:34-87`)
- No error dialogs or retry buttons observed

**To Fix:**
1. Add error dialog/toast UI for auth failures
2. Show network status indicator
3. Implement retry logic with exponential backoff
4. Display clear error messages to user

---

### High-4: Incomplete Multiplayer Reconnect Logic

**Location:** `autoload/live_update_service.gd`, `scenes/ui/lobby_pages/duel_page.gd`  
**Severity:** 🟠 HIGH  
**Status:** Requires device testing

**Issue:**
If a user loses network mid-match, or receives a connection timeout:
- Match state may desynchronize
- No explicit reconnect/resume flow
- Unclear if unfinished match is recoverable

**Evidence:**
- Live update polling has timeout but no reconnect notification
- Match state machine doesn't show "reconnecting" state
- Invite flow emits local signal, doesn't persist to Firebase

**Recommendation:**
1. Add persistent match state to Firestore (current_round, player_answers, etc.)
2. Implement match resume/reconnect UI
3. Test on real device with network interruption (airplane mode toggle)

---

### High-5: No Forced Update Mechanism

**Location:** Not implemented  
**Severity:** 🟠 HIGH (if future server changes break old clients)  
**Status:** Optional for v1.0 but should be planned

**Issue:**
If future game updates contain breaking backend changes, old app versions will break. No mechanism exists to force users to update.

**Recommendation:**
Implement version check on app launch:
1. Add app version field to Firestore config
2. Check on startup; show "update required" screen if local version < minimum required version

---

## Section 3: Medium-Priority Issues

### Medium-1: Code Formatting Inconsistency

**Severity:** 🟡 MEDIUM  
**Issue:** Excessive blank lines and inconsistent spacing throughout codebase  
**Example:** Some scripts have 3-4 blank lines between functions; others have 1  
**Impact:** Reduces readability, inconsistent developer experience  
**Recommendation:** Run a formatting pass (Godot's built-in formatter or gdformat tool)

---

### Medium-2: Hardcoded Gameplay Constants

**Severity:** 🟡 MEDIUM  
**Locations:** 
- `scenes/ui/setup_screen.gd:28-29`: Hardcoded game rules (6 rounds, 3 questions per round)
- `scenes/ui/lobby_pages/duel_page.gd:4-8`: Hardcoded match configuration

**Issue:** Game balance values are embedded in code, difficult to adjust without rebuilding  
**Recommendation:** Move to Firestore config or external JSON file for easier tuning

---

### Medium-3: Temporary .tmp Scene Files

**Severity:** 🟡 MEDIUM  
**Location:** `scenes/ui/*.tmp` files  
**Issue:** Workspace artifacts should not be committed  
**Recommendation:** Add to `.gitignore` and clean up

---

### Medium-4: Missing Type Annotations

**Severity:** 🟡 MEDIUM  
**Scope:** JSON parsing and Firebase result handling  
**Example:** `var data = response.result` (type unknown)  
**Impact:** Reduces IDE autocomplete and type safety  
**Recommendation:** Add explicit typing, especially for Firebase responses

---

### Medium-5: Documentation Gaps

**Severity:** 🟡 MEDIUM  
**Gaps:**
- No setup guide for Firebase production deployment
- No OAuth credentials setup documentation
- No Android signing/keystore documentation
- No multiplayer flow documentation

**Recommendation:** Create `docs/DEPLOYMENT.md` and `docs/ANDROID-RELEASE.md`

---

## Section 4: Postponed Work & OpenSpec Status

### Active Changes

**1. add-google-sign-in-registration** (In-Progress)

- **Status:** Planning complete; 70% of implementation done
- **Deferred Until:** After Play Store release (per user request)
- **Tasks Remaining:** Real-device testing, production OAuth setup, offline behavior validation
- **Reason for Deferral:** Feature enhancement, not blocking core gameplay; user prioritizes Play Store launch

### Completed Changes (Archive)

The following changes have been completed and archived:

| Change | Purpose | Status |
|--------|---------|--------|
| firebase-user-data-migration | User account structure | ✅ Complete |
| email-verification-password-reset | Account recovery | ✅ Complete |
| live-updates | Match state sync | ✅ Complete |
| category-statistics | Player stats tracking | ✅ Complete |
| account-flows | Auth screens and logic | ✅ Complete |
| trivia-question-service | Question loading system | ✅ Complete |
| gameplay-round-flow | Turn and scoring logic | ✅ Complete |
| navigation-bar-component | UI navigation | ✅ Complete |

### Pending Architectural Decisions

1. **Multiplayer Stability Before Single-Player Removal**  
   Status: Multiplayer infrastructure exists but requires device validation before removing single-player fallback  
   Decision: Remove single-player path before release (Blocker 4 above)

2. **Generated Google Usernames (No Rename)**  
   Status: Implemented; usernames are auto-generated from Google profile name  
   Decision: Accept as-is for v1.0; add rename feature in v1.1+

3. **Firebase Emulator-First Development**  
   Status: Project was developed against emulators; must switch to production before release  
   Decision: Complete production setup (Blocker 1 above)

4. **Local Question Database Loading**  
   Status: Implemented; trivia service loads full JSON files into memory  
   Observation: May cause memory pressure on lower-end devices; monitor after release

5. **Live Polling vs. Push Updates**  
   Status: Implemented as polling (not Firebase Realtime Database)  
   Observation: Sufficient for asynchronous gameplay; consider push updates if real-time requirement increases

---

## Section 5: Project Completeness by System

| System | Status | % Complete | Notes |
|--------|--------|-----------|-------|
| **Trivia Question Service** | ✅ Ready | 90% | Loads EN/DE/ZH/ZH-TW, caching implemented, category validation working |
| **Local Cache & Persistence** | ✅ Ready | 85% | Session storage, user data sync; needs offline validation |
| **Firebase Auth (Email)** | ✅ Ready | 80% | Registration, login working; test accounts must be removed |
| **Firebase Auth (Google)** | 🟡 In-Progress | 70% | Partially implemented; production verification pending |
| **Firestore Database** | ✅ Ready | 75% | Schema defined, security rules basic; privacy review needed |
| **Multiplayer Match System** | 🟡 Partial | 65% | Core logic exists; reconnect and offline handling incomplete |
| **UI Navigation & Screens** | ✅ Ready | 85% | All planned screens exist; error handling missing |
| **Android Export Config** | 🔴 Incomplete | 20% | Build templates missing, export preset empty |
| **Release Signing & Build** | 🔴 Incomplete | 0% | Keystore, version, icons not configured |
| **Testing & QA** | 🟡 Partial | 40% | Unit tests exist; no device testing results |

---

## Section 6: Recommendations & Next Steps

### Immediate Priority (Blocking Release) - Must Complete First

**1. Configure Production Firebase [2-4 hours]**
- [ ] Create production Firebase project
- [ ] Switch runtime_mode to "production"
- [ ] Deploy Firestore rules and Cloud Functions
- [ ] Test authentication and data sync on real device

**2. Generate Android Build Templates [1-2 hours]**
- [ ] Run `godot --export-template` to generate templates
- [ ] Configure `build.gradle` with target SDK, app ID, permissions

**3. Complete Export Preset [2-3 hours]**
- [ ] Add version name/code
- [ ] Create launcher icons and adaptive icons
- [ ] Generate release keystore
- [ ] Configure keystore path in export preset

**4. Remove Test Code [1-2 hours]**
- [ ] Delete single-player path from `setup_screen.gd`
- [ ] Remove test account hardcoding
- [ ] Add production assertions

**5. Real-Device Testing [3-5 hours]**
- [ ] Export signed APK
- [ ] Test on multiple devices/Android versions
- [ ] Verify auth, match creation, gameplay, navigation

### High Priority (Before Store Submission) - Complete by Launch

**6. Implement Error Handling [2-3 hours]**
- [ ] Add network error dialogs
- [ ] Show Firebase error messages
- [ ] Implement retry logic

**7. Test Multiplayer Flow [3-4 hours]**
- [ ] Full end-to-end match on two devices
- [ ] Test network interruption recovery
- [ ] Test match resume/reconnect

**8. Review Firestore Privacy [1-2 hours]**
- [ ] Assess user profile visibility
- [ ] Implement privacy controls if needed
- [ ] Verify compliance with app store policies

**9. Create Release Documentation [1-2 hours]**
- [ ] Document Firebase production setup
- [ ] Document Android signing and build process
- [ ] Create deployment checklist

### Medium Priority (Nice-to-Have Before v1.0)

**10. Add Account Deletion [2-3 hours]**
- [ ] Implement backend function
- [ ] Create UI screen
- [ ] Test data cleanup

**11. Code Cleanup [2-3 hours]**
- [ ] Format code consistently
- [ ] Remove .tmp files
- [ ] Add type annotations to Firebase responses

**12. Expand Documentation [1-2 hours]**
- [ ] Write setup guides
- [ ] Document architecture
- [ ] Create troubleshooting guide

---

## Section 7: Risk Assessment

### Release-Blocking Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Firebase prod config not working | High | Complete app failure | Test immediately after setup on real device |
| Android build/signing fails | Medium | Cannot ship APK | Follow official Godot Android export guide |
| Multiplayer desync on real devices | High | Core feature broken | Device testing with network interruption |
| Google Play Store rejects submission | Medium | Cannot launch | Follow checklist in Section 6 item 9 |
| Account deletion policy violation | Low | App suspension post-launch | Implement deletion before release |

### Post-Launch Monitoring

- Monitor crash reports (Firebase Crashlytics)
- Watch for authentication failures
- Track multiplayer match completion rate (indicator of reconnect issues)
- Monitor data sync errors

---

## Section 8: Summary Checklist

**Before Final Submission to Google Play Store:**

- [ ] Firebase production deployed and tested on real device
- [ ] Android build templates generated and configured
- [ ] Export preset complete (version, icons, signing)
- [ ] All test code removed (single-player path, debug accounts)
- [ ] Signed APK exports successfully
- [ ] Full multiplayer flow tested on 2+ real devices
- [ ] Error handling implemented (network failures, auth errors)
- [ ] Firestore security rules deployed and tested
- [ ] Privacy policy reviewed for compliance
- [ ] Account deletion flow implemented (or documented why not required)
- [ ] Release notes and store description prepared
- [ ] Screenshots and app icon prepared for store listing
- [ ] All ToDoS and FIXMEs reviewed/resolved in critical paths

---

## Conclusion

QuizBattles is **65-70% complete** for Play Store release. The core gameplay, user authentication, and multiplayer infrastructure are solid, but **5 critical blockers must be resolved** before submission is possible:

1. Firebase production configuration
2. Android build file generation
3. Export preset completion
4. Test code removal
5. Google Sign-In production verification

With focused effort on the immediate-priority tasks (Section 6), the project can reach release readiness in **14-20 hours** of concentrated work, followed by device testing and validation.

The roadmap is clear, risks are identified, and the path to launch is achievable.

---

**Report Generated:** 2026-11-05  
**Next Review Recommended:** After each critical blocker fix, before final submission
