## Context

The QuizBattles project is feature-complete in its core gameplay systems (local trivia, multiplayer setup, Firebase integration, Android export configuration). However, the project is at approximately 65-70% completion for Google Play Store readiness. Critical gaps remain in production Firebase configuration, Android build/signing setup, and final device validation. The add-google-sign-in-registration feature is actively being worked on but the user explicitly requests postponement until after Play Store release.

An audit is needed to consolidate all findings and provide a clear, prioritized roadmap to closure.

## Goals / Non-Goals

**Goals:**

1. **Identify all critical blockers** that prevent Play Store submission
2. **Document code issues** (bugs, incomplete features, quality gaps) with evidence
3. **List postponed work** and pending design decisions
4. **Provide actionable recommendations** prioritized by impact and urgency
5. **Establish baseline** for release readiness and acceptance criteria
6. **Create a single source of truth** for pre-release validation

**Non-Goals:**

- Implement fixes or make code changes
- Create new features or modify gameplay systems
- Generate deployment scripts or automation
- Provide design mockups or UI specifications
- Propose architectural changes
- Write implementation tasks (this is analysis only)

## Decisions

### Decision 1: Analysis Scope

**What:** This audit covers the entire project (code, configuration, OpenSpec planning documents, tests, documentation).

**Rationale:** Comprehensive coverage ensures no critical gaps are missed before submission.

**Alternatives considered:** 
- Focus only on critical path → Risk: miss lower-priority issues that cause post-launch problems
- Audit only recent changes → Risk: miss long-standing issues in core systems

### Decision 2: Single Consolidated Report

**What:** Deliverable is one markdown document (`PRE-RELEASE-READINESS-REPORT.md`) in the project root, not scattered notes or multiple files.

**Rationale:** Single source of truth is easier to maintain, reference, and act upon; clear format for stakeholders.

**Alternatives considered:**
- Separate reports by subsystem → Risk: fragmentation, harder to see cross-system dependencies
- Spreadsheet/CSV format → Risk: harder to include code context and narrative

### Decision 3: Severity Tiers for Issues

**What:** Issues are categorized as **CRITICAL** (blocks release), **HIGH** (must fix before launch), **MEDIUM** (should fix), **LOW** (nice-to-have).

**Rationale:** Enables clear prioritization and risk assessment; helps allocate effort efficiently.

### Decision 4: Evidence-Based Claims

**What:** Every issue includes file path, line numbers, and code excerpt or configuration reference.

**Rationale:** Removes ambiguity, enables developers to verify and act on findings, improves credibility.

### Decision 5: Explicit Postponement of Google Sign-In Testing

**What:** The report documents that Google Sign-In (add-google-sign-in-registration change) is deferred until after Play Store release and will not block this submission.

**Rationale:** User explicitly requested this; it's a feature enhancement, not a core gameplay blocker.

## Risks / Trade-offs

### Risk 1: Report May Be Large
**Impact:** Large reports can be hard to navigate.  
**Mitigation:** Use table of contents, clear section headers, and executive summary at the top.

### Risk 2: Findings May Conflict with Prior Documentation
**Impact:** If project docs claim something is done but code shows it's not, credibility questions arise.  
**Mitigation:** Report clearly notes discrepancies; cites both the claimed state and observed reality.

### Risk 3: Real-Device Testing Not Included
**Impact:** Some issues (e.g., multiplayer reconnect, offline login) can only be found on real devices.  
**Rationale:** Report notes gaps and recommends device testing as a task; analysis is static-only.

### Trade-off 1: Depth vs. Breadth
**Decision:** Prioritize breadth (cover all systems) over deep analysis of each. Developers can drill deeper into specific areas after the report prioritizes them.

### Trade-off 2: Future-Proofing vs. Readiness
**Decision:** Report focuses on play-store-readiness (now), not long-term maintainability (future). Long-term tech debt is noted but deprioritized.
