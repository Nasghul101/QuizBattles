## Purpose

A comprehensive readiness report that audits the QuizBattles project before Google Play Store submission, identifying critical blockers, code issues, pending work, and actionable recommendations.

## ADDED Requirements

### Requirement: Identify Critical Play Store Blockers

The report must list all issues that **prevent** Play Store submission or would cause rejection/suspension post-release.

#### Scenario: Firebase configuration blockers
- **WHEN** analyzing project.godot and firebase.json
- **THEN** report identifies emulator-mode runtime settings, localhost endpoints, and missing production configuration

#### Scenario: Android export blockers
- **WHEN** examining export_presets.cfg and android/ directory
- **THEN** report flags missing Gradle/build-template files, release keystore, app version, launcher icons, and SDK configuration

#### Scenario: Google Sign-In blockers
- **WHEN** reviewing the add-google-sign-in-registration change
- **THEN** report identifies pending real-device testing, OAuth production verification, and Firebase configuration requirements

### Requirement: Document All Code Issues

The report must categorize code quality issues and incomplete features by severity, with file references and line numbers.

#### Scenario: Critical issues
- **WHEN** examining Firebase integration and multiplayer logic
- **THEN** report lists issues that could cause crashes, data loss, or security vulnerabilities, with severity level

#### Scenario: High-priority issues
- **WHEN** reviewing UI/UX screens and error handling
- **THEN** report documents missing error states, incomplete flows, and offline handling gaps

#### Scenario: Medium-priority issues
- **WHEN** inspecting code consistency and documentation
- **THEN** report notes code formatting inconsistencies, missing type annotations, and incomplete documentation

### Requirement: List All Postponed Work

The report must document postponed features, design decisions, and active OpenSpec changes.

#### Scenario: Active changes
- **WHEN** scanning openspec/changes/
- **THEN** report notes that add-google-sign-in-registration is in-progress and deferred until after Play Store release

#### Scenario: Archived changes
- **WHEN** reviewing openspec/changes/archive/
- **THEN** report confirms completed work (Firebase migration, email verification, live updates, account flows, etc.)

### Requirement: Provide Actionable Recommendations

The report must prioritize next steps for finalizing the release.

#### Scenario: Immediate actions (blocking release)
- **WHEN** synthesizing critical issues
- **THEN** report lists 5-7 highest-priority tasks with estimated effort and dependencies

#### Scenario: Pre-launch actions (required before submission)
- **WHEN** analyzing testing and configuration gaps
- **THEN** report lists device testing, configuration deployment, and final validation tasks

#### Scenario: Post-launch monitoring (optional)
- **WHEN** identifying lower-priority improvements
- **THEN** report notes non-blocking enhancements and future work

### Requirement: Ground All Findings in Code Evidence

The report must cite specific files, line ranges, or configuration sections for every claim.

#### Scenario: Code references
- **WHEN** describing an issue
- **THEN** report includes file path and line numbers (e.g., `scenes/ui/setup_screen.gd:66–77`)

#### Scenario: Configuration references
- **WHEN** documenting missing settings
- **THEN** report references export presets, gradle properties, or Firebase configuration by section

### Requirement: Scope Clarity

The report documents current project state **without proposing code changes**—it is a read-only analysis artifact only.

#### Scenario: Analysis only
- **WHEN** reviewing the report
- **THEN** reader understands it is a diagnostic document with no implementation tasks or code patches
