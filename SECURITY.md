# Security Policy

## Reporting a vulnerability

Please email security issues to MySwallow on GitHub (open a GitHub
Security Advisory, not a public issue):

https://github.com/MySwallow/flutter-visual-loop/security/advisories/new

You should hear back within 48 hours.

## Threat model — what the SDK guards against

The `flutter_visual_loop` SDK is **debug-tooling**, not a production
component. Its threat model is therefore narrow:

| Threat                                       | Mitigation                                                   |
|----------------------------------------------|--------------------------------------------------------------|
| Accidentally shipping the control plane to production users | `enableInDebugOnly: true` by default — `start()` is a no-op in release builds |
| Local malware reads/writes mock data         | Bind to `127.0.0.1` only; do not bind `0.0.0.0`              |
| Network attacker on Wi-Fi                    | Bind to `127.0.0.1` only                                     |
| DoS via huge body                            | `maxBodyBytes` defaults to 1 MiB; larger requests get 413    |
| Malicious deep-link from another app         | The control plane is **not** a deep-link handler; cannot be invoked from another Android app without `adb forward` |

## What the SDK does NOT guard against

- **Same-device attackers**: anyone with code execution on your phone
  can reach `127.0.0.1:9123`. If your dev device is compromised, this
  SDK is the least of your worries.
- **Eavesdropping over `adb forward`**: traffic between your laptop and
  the device is unencrypted. Don't run the loop over public USB hubs
  in untrusted environments.
- **Mock data leakage**: mock values may contain sensitive fixtures
  (auth tokens, user records). They live in app memory and disappear
  when the app dies. Don't put real production secrets there.

## Hardening tips for your CI / shared dev environments

- Set `enableInDebugOnly: true` (default).
- Pin a non-default port if multiple Flutter projects share the laptop:
  ```dart
  VisualLoopConfig(port: 9124)
  ```
- After CI, ensure `adb forward --remove tcp:9123` runs (or
  `--remove-all`) so other jobs don't accidentally hit a stale server.
- Do not commit example mock data that contains real user PII.

## Supported versions

| Version | Supported          |
|---------|--------------------|
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |
