# Test drive — Oink 1.0.0 · 2026-10-07 12:59
iPhone 17 Pro (8E58B515) · Xcode 27.0 · build failed after ~9 s · commit 4460ee0 · seams: DEBUG_RESET_FIRST_RUN, DEBUG_INSPECTOR

PASS 0 · FAIL 1 · BLOCKED 46 · SKIP 0   (of 47 criteria incl. F0)

| Criterion | Verdict | Evidence | Note |
| --- | --- | --- | --- |
| F0 builds for the simulator | **FAIL** | test-drive/20261007-1258/F0-build.log | expected a build; observed `IPHONEOS_DEPLOYMENT_TARGET is set to 13.0, but the range of supported deployment target versions is 15.0 to 27.0.x` |
| F1–F12 (all criteria) | BLOCKED | — | no installable build |

## Regressions
None (no previous report).

## Findings
- Known factory trap (app-factory `docs/TRAPS.md`, "Deployment target below Xcode's floor"): Oink was scaffolded before the template moved to 15.0 and lacks `test/ios_deployment_target_test.dart`. Release builds fail the same way.

## Next for /build
| F0 builds for the simulator | **FAIL** | test-drive/20261007-1258/F0-build.log | expected a build; observed `IPHONEOS_DEPLOYMENT_TARGET is set to 13.0, but the range of supported deployment target versions is 15.0 to 27.0.x` |
