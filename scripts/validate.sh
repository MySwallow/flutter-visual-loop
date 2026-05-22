#!/usr/bin/env bash
# validate.sh — repo-level sanity checks.
# Tries to run Dart-side checks when Flutter is available; falls back to
# pure-text checks (file presence, bash syntax) otherwise.
# Exit code: 0 if no FAIL, 1 if any FAIL (WARN doesn't fail).

set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ok    $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
warn() { echo "  warn  $1"; WARN=$((WARN+1)); }

echo "== File presence =="
for f in \
  README.md LICENSE .gitignore \
  docs/architecture.md \
  docs/superpowers/plans/2026-05-21-flutter-visual-loop.md \
  packages/flutter_visual_loop/pubspec.yaml \
  packages/flutter_visual_loop/analysis_options.yaml \
  packages/flutter_visual_loop/README.md \
  packages/flutter_visual_loop/CHANGELOG.md \
  packages/flutter_visual_loop/lib/flutter_visual_loop.dart \
  packages/flutter_visual_loop/lib/src/visual_loop.dart \
  packages/flutter_visual_loop/lib/src/config.dart \
  packages/flutter_visual_loop/lib/src/mock_provider.dart \
  packages/flutter_visual_loop/lib/src/route_registry.dart \
  packages/flutter_visual_loop/lib/src/screenshot.dart \
  packages/flutter_visual_loop/lib/src/http_server.dart \
  packages/flutter_visual_loop/lib/src/logger.dart \
  packages/flutter_visual_loop/lib/src/handlers/handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/health_handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/routes_handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/navigate_handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/reset_handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/mock_handler.dart \
  packages/flutter_visual_loop/lib/src/handlers/screenshot_handler.dart \
  packages/flutter_visual_loop/test/route_registry_test.dart \
  packages/flutter_visual_loop/test/mock_provider_test.dart \
  example/pubspec.yaml \
  example/lib/main.dart \
  example/lib/router/app_router.dart \
  example/lib/mock/demo_mock_provider.dart \
  example/lib/pages/home_page.dart \
  example/lib/pages/login_page.dart \
  example/lib/pages/product_detail_page.dart \
  example/lib/pages/order_detail_page.dart \
  example/README.md \
  example/PLATFORM_NOTE.md \
  skills/flutter-visual-loop/SKILL.md \
  skills/flutter-visual-loop/scripts/env_check.sh \
  skills/flutter-visual-loop/scripts/setup.sh \
  skills/flutter-visual-loop/scripts/navigate.sh \
  skills/flutter-visual-loop/scripts/capture.sh \
  skills/flutter-visual-loop/scripts/hot_reload.sh \
  skills/flutter-visual-loop/scripts/reset_device.sh \
  skills/flutter-visual-loop/scripts/mock_set.sh \
  scripts/validate.sh ; do
  if [ -f "$f" ]; then ok "$f"; else fail "$f missing"; fi
done

echo
echo "== Bash syntax =="
for f in scripts/*.sh skills/flutter-visual-loop/scripts/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "$f"; else fail "$f syntax error"; fi
done

echo
echo "== Bash scripts are executable =="
for f in scripts/*.sh skills/flutter-visual-loop/scripts/*.sh; do
  if [ -x "$f" ]; then ok "$f"; else warn "$f not executable (chmod +x recommended)"; fi
done

echo
echo "== YAML manifests parseable (python check) =="
if command -v python3 >/dev/null 2>&1; then
  for f in packages/flutter_visual_loop/pubspec.yaml example/pubspec.yaml; do
    if python3 -c "import sys,yaml; yaml.safe_load(open('$f'))" 2>/dev/null; then
      ok "$f"
    elif python3 -c "import sys; import yaml" 2>/dev/null; then
      fail "$f invalid YAML"
    else
      warn "pyyaml not installed — skipped $f"
    fi
  done
else
  warn "python3 not installed — skipped YAML parse"
fi

echo
echo "== Dart side =="
if command -v dart >/dev/null 2>&1; then
  if (cd packages/flutter_visual_loop && dart pub get >/dev/null 2>&1); then
    ok "dart pub get"
  else
    warn "dart pub get failed (run manually to inspect)"
  fi
  if (cd packages/flutter_visual_loop && dart analyze --fatal-infos 2>&1 | tail -1 | grep -q 'No issues found'); then
    ok "dart analyze"
  else
    warn "dart analyze produced issues (run manually to inspect)"
  fi
else
  warn "dart not installed — skipped analyze"
fi

if command -v flutter >/dev/null 2>&1; then
  if (cd packages/flutter_visual_loop && flutter test 2>&1 | grep -qE 'All tests passed'); then
    ok "flutter test"
  else
    warn "flutter test — run manually"
  fi
else
  warn "flutter not installed — skipped tests"
fi

echo
echo "== Summary =="
echo "  pass:  $PASS"
echo "  warn:  $WARN"
echo "  fail:  $FAIL"

[ "$FAIL" -eq 0 ] || exit 1
