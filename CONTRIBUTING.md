# Contributing

Thanks for considering a contribution. This project is intentionally
small — the SDK is ~1k lines of Dart and the skill is a few hundred
lines of bash. Keep it that way.

## Ground rules

1. **No new dependencies in the SDK.** `dart:io` and `package:flutter`
   are all we need. PRs that add `http`, `riverpod`, `dio`, etc. will
   be rejected. Host apps shouldn't pay for dependencies they don't use.
2. **Production-safety first.** Any new code path must be gated by
   `kDebugMode` or a config flag defaulted to off. Releases must never
   bind a socket or expose any data.
3. **Small files.** Keep files under ~400 lines. One handler per file.
4. **No backwards-compat shims.** v0.x is unstable. Breaking changes
   are fine as long as they're called out in `CHANGELOG.md`.

## Setup

```bash
git clone https://github.com/MySwallow/flutter-visual-loop.git
cd flutter-visual-loop/packages/flutter_visual_loop
flutter pub get
flutter test
```

For the example app:

```bash
cd flutter-visual-loop/example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
flutter run -d <device-id>
```

## What we want PRs for

- Bug fixes (with a failing test added first).
- iOS Simulator parity (UNIX socket or simctl-based capture).
- Web platform support (run SDK in Flutter Web).
- Better error messages.
- Documentation improvements.

## What we DON'T want PRs for

- Visual diffing algorithms — the LLM does that at skill level.
- HTTP authentication — bind to localhost is the security model.
- "Reactive" mock data with streams — keep `MockDataProvider` simple.

## PR checklist

Before opening a PR:

- [ ] `flutter test` passes in `packages/flutter_visual_loop`
- [ ] `bash scripts/validate.sh` shows 0 FAIL
- [ ] If you added a new endpoint, updated `docs/api-reference.md` and
      `packages/flutter_visual_loop/README.md`
- [ ] If you changed default behavior, added a `CHANGELOG.md` entry
- [ ] Commit messages follow conventional commits (`feat:`, `fix:`,
      `docs:`, `refactor:`, `test:`, `chore:`)

## Review process

PRs are reviewed by the maintainer (MySwallow). Expect feedback within
a week. The bar is "small change, well-tested, minimal blast radius".

## License

By contributing, you agree your code is licensed under MIT.
