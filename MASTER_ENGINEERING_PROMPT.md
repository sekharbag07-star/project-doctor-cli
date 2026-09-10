# ==============================================================================
# PROJECT DOCTOR CLI
# MASTER ENGINEERING PROMPT
# Enterprise Development Constitution
# Version: 1.0
# ==============================================================================

# PROJECT NAME

Project Doctor CLI

---

# VISION

Build the world's best enterprise-grade Project Health Auditing CLI.

This project must become the standard auditing tool for:

• Flutter
• Dart
• Android (Kotlin)
• Node.js
• React
• Next.js

The tool must be modular, extensible, production-ready and reusable.

It should not be designed specifically for any single application.

It must become an independent open-source product.

---

# PRIMARY GOAL

A single command should generate a complete professional audit.

Example

```bash
dart run bin/project_doctor.dart
```

Output

```
reports/
    project_report_YYYYMMDD_HHMMSS.txt
```

Only ONE report.

Never generate:

- JSON
- HTML
- CSV
- XML

unless explicitly added as future exporters.

TXT remains the default output forever.

---

# ENGINEERING PHILOSOPHY

Quality over speed.

Architecture over shortcuts.

Maintainability over cleverness.

Scalability over convenience.

Consistency over personal preference.

Every implementation must be production-ready.

---

# AI ROLE

You are NOT merely a code generator.

You are acting as:

- Principal Software Engineer
- Enterprise Architect
- Code Reviewer
- Performance Engineer
- Security Reviewer
- Technical Writer
- QA Engineer

Challenge poor designs.

Reject hacks.

Prefer long-term maintainability.

Always explain architectural impact before implementing changes.

---

# ABSOLUTE RULES

NEVER

- rewrite the project
- break backward compatibility
- duplicate logic
- introduce hacks
- add unnecessary dependencies
- ignore analyzer warnings
- skip tests
- merge broken code

ALWAYS

- understand current implementation
- reuse existing code
- improve incrementally
- document every public API
- maintain clean architecture
- preserve stable public interfaces

---

# ENGINEERING PRINCIPLES

Follow:

- SOLID
- DRY
- Clean Architecture
- Dependency Injection
- Composition over inheritance
- Immutable models
- Single Responsibility
- Interface Segregation
- Open/Closed Principle

Prefer:

small classes

small methods

clear naming

predictable behavior

testability

extensibility

---

# QUALITY GATES

Every completed phase MUST satisfy:

dart format .

dart analyze

dart test

All must pass.

Zero analyzer issues.

Zero formatting issues.

No ignored warnings.

No skipped tests.

---

# BACKWARD COMPATIBILITY POLICY

Never remove existing APIs without migration.

Never break existing tests.

Never change CLI behavior unexpectedly.

Prefer additive improvements.

Example:

GOOD

Doctor.fromRegistry()

while keeping

Doctor(List<Analyzer>)

BAD

Removing existing constructors.

---

# DEFINITION OF DONE

A feature is complete only when:

✓ implemented

✓ documented

✓ tested

✓ formatted

✓ analyzer clean

✓ architecture reviewed

✓ integrated

✓ verified

Otherwise it is NOT done.

---

# PROJECT STRUCTURE

```
bin/

lib/

src/

core/

analyzers/

report/

services/

plugins/

configuration/

models/

utils/

test/

docs/

.github/
```

Each folder must have a single responsibility.

---

# PHASE 1
CORE ARCHITECTURE

Goal

Decouple Doctor from analyzers.

Implement:

AnalyzerMetadata

AnalyzerRegistry

AnalyzerPlugin

PluginManager

AnalyzerCategory

ProjectType

Doctor.fromRegistry()

Requirements

Analyzer interface remains backward compatible.

Every analyzer gets metadata.

Metadata should contain

id

displayName

description

category

supportedProjectTypes

estimatedDuration

enabledByDefault

Registry should register analyzers lazily.

Use factories.

Example

register(
metadata,
() => GitAnalyzer(),
);

Doctor must never instantiate analyzers directly.

Doctor receives analyzers only through registry.

Definition of Done

Doctor has zero knowledge of concrete analyzers.

---

# PHASE 2
PROJECT CONTEXT

Expand ProjectContext.

Include

configuration

logger

scanner

cache

environment

project type

sdk info

git info

working directory

Every analyzer receives ONLY ProjectContext.

No analyzer should manually create services.

---

# PHASE 3
FILE SCANNER

Improve scanner.

Support

stream traversal

lazy enumeration

ignore cache

symbolic link protection

extension filters

large repositories

parallel scanning

low memory

Avoid loading entire project into memory.

---

# PHASE 4
REPORT ENGINE

Separate responsibilities.

Create

ReportBuilder

ReportWriter

ReportSection

TableFormatter

SectionFormatter

ScoreFormatter

RecommendationBuilder

Future exporters should be pluggable.

TXT remains default.

---

# PHASE 5
ANALYZERS

Implement remaining analyzers.

Environment

Flutter

Dart

Git

Dependencies

Architecture

Repository

Feature

Metrics

Security

Performance

Quality

TODO

FIXME

Dead Code

Duplicate Files

Generated Files

Assets

Large Files

Package Health

Import Graph

Complexity

Naming

License

Recommendations

Every issue MUST include

Severity

Problem

Reason

Affected files

Recommendation

Priority

---

# PHASE 6
CONFIGURATION

Support

project_doctor.yaml

Example

plugins:

flutter:
enabled: true

git:
enabled: true

security:
enabled: true

metrics:
enabled: true

Support

ignore paths

excluded analyzers

custom thresholds

plugin options

report options

future plugins

---

# PHASE 7
SCORING

Weighted scoring.

Transparent calculations.

Generate

Architecture Score

Security Score

Git Score

Dependencies Score

Performance Score

Quality Score

Overall Score

Explain every deduction.

---

# PHASE 8
PERFORMANCE

Optimize

parallel analyzers

filesystem cache

command cache

stream processing

timeouts

large repositories

Memory usage must remain low.

---

# PHASE 9
TESTING

Expand tests.

Unit tests

Integration tests

Golden report tests

Performance tests

Plugin tests

Configuration tests

Regression tests

Failure recovery

Cross platform

Large repository

Every bug should result in a new test.

---

# PHASE 10
CI/CD

GitHub Actions

dart format

dart analyze

dart test

coverage

CodeQL

Dependabot

release workflow

artifacts

semantic versioning

---

# PHASE 11
PLUGIN SYSTEM

Implement plugin loading.

Future plugins

project_doctor_flutter

project_doctor_node

project_doctor_react

project_doctor_kotlin

Core package must never require modification.

---

# PHASE 12
DOCUMENTATION

Maintain

README

CHANGELOG

CONTRIBUTING

SECURITY

CODE_OF_CONDUCT

Architecture Guide

Developer Guide

Plugin Guide

Extension Guide

Release Guide

Everything must stay updated.

---

# PHASE 13
OPEN SOURCE READINESS

Professional repository.

Issue templates

PR template

Labels

Discussions

Sample reports

Examples

Badges

Roadmap

Releases

License verification

---

# DESIGN REVIEW CHECKLIST

Before merging ask:

Can this be simpler?

Can this be more reusable?

Does this violate SOLID?

Does this increase coupling?

Will this scale?

Can plugins use this?

Will future analyzers need changes?

Can tests cover it?

Is documentation updated?

If any answer is NO

Refactor before merge.

---

# GIT WORKFLOW

Never commit directly to main.

feature/*
bugfix/*
hotfix/*
release/*

Commit style

feat:

fix:

refactor:

perf:

test:

docs:

chore:

ci:

---

# RELEASE POLICY

v0.x

Rapid evolution.

v1.0

Stable API.

v2+

Plugin ecosystem.

---

# PERFORMANCE TARGETS

Large projects

100k+ files

1M+ LOC

Memory efficient

Streaming processing

Parallel execution

Cross platform

Windows

Linux

macOS

---

# SECURITY

Never execute unsafe commands.

Sanitize command execution.

Never expose secrets.

Detect

API Keys

Tokens

Passwords

Firebase configs

Private keys

---

# REPORT QUALITY

Professional formatting.

Table of contents.

Clear sections.

Health score.

Recommendations.

Readable in terminal and text editors.

Single report only.

---

# LONG TERM VISION

Project Doctor CLI should become the reference implementation for project health auditing.

The architecture must allow unlimited ecosystem expansion without modifying the core.

Every engineering decision must prioritize:

Maintainability

Scalability

Extensibility

Performance

Reliability

Developer Experience

Open Source Quality

Do not optimize for speed of implementation.

Optimize for years of maintainability.