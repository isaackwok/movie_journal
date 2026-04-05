---
name: deploy
description: >
  Deploy the app to App Store Connect / TestFlight. Use this skill whenever the
  user mentions "deploy", "upload to app store", "push to TestFlight", "build IPA",
  "release a build", "ship it", "distribute", "publish", "send to TestFlight",
  "new build", or otherwise wants to get a build onto App Store Connect or into
  testers' hands. Also use when the user asks about deployment status, build
  numbers, or troubleshooting upload failures.
---

# Deploy to App Store Connect / TestFlight

This skill runs the full build-validate-upload pipeline via `deploy.sh`.

## Pre-flight Checks

Before running the deploy, verify these conditions and tell the user about any
issues. Don't silently skip checks.

1. **Credentials exist** — `.deploy.env` must contain `ASC_API_KEY` and
   `ASC_API_ISSUER` with real values (not the placeholder text). Read the file
   and check.
2. **API key file exists** — The `.p8` file must be at
   `~/.appstoreconnect/private_keys/AuthKey_<ASC_API_KEY>.p8`. Check with `ls`.
3. **Flutter available** — `flutter --version` should succeed.
4. **No uncommitted changes** (optional warning) — Run `git status --short`. If
   there are uncommitted changes, warn the user but don't block. They may want
   to deploy a work-in-progress build for testing.

If credentials or the API key file are missing, walk the user through the
one-time setup:
1. App Store Connect > Users and Access > Integrations > App Store Connect API
2. Create key with "Developer" role, download the `.p8` file
3. Place at `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
4. Fill in `.deploy.env` with Key ID and Issuer ID

## Running the Deploy

```bash
./deploy.sh
```

Or with an explicit build number:

```bash
./deploy.sh --build-number <N>
```

By default, App Store Connect auto-manages the build number (increments each
upload), so passing `--build-number` is rarely needed.

The script runs: `flutter clean` > `flutter pub get` > `flutter build ipa --release`
> `xcrun altool --validate-app` > `xcrun altool --upload-package`.

The build takes several minutes. Run it and let the user know when each stage
completes. If any stage fails, diagnose the error before retrying.

## Version Management

The app version lives in `pubspec.yaml` as `version: X.Y.Z+buildNumber`.

- **Build number** — auto-managed by App Store Connect on each upload. Only
  override with `--build-number` if you have a specific reason.
- **Version string** (X.Y.Z) — bump in `pubspec.yaml` when the user wants a new
  user-visible version. This is a manual decision — ask the user before changing it.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ERROR: Set ASC_API_KEY` | Missing or empty `.deploy.env` | Fill in API credentials |
| `No IPA file found` | Build failed silently | Check `flutter build ipa` output for errors |
| `altool: could not find API key` | `.p8` file not in expected location | Move to `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` |
| `ERROR ITMS-90189: Redundant Binary Upload` | Build number already used | Either omit `--build-number` (let ASC auto-manage) or use a higher number |
| `ERROR ITMS-90046: Invalid Code Signing` | Signing certificate issue | Open Xcode > Runner.xcodeproj > Signing & Capabilities, verify team and automatic signing |
| `ERROR ITMS-90035: Invalid Signature` | Archive signed with wrong cert | Run `flutter clean` then rebuild — stale artifacts can cause this |

## After Upload

Tell the user:
- The build will appear in App Store Connect / TestFlight in ~15-30 minutes
- No encryption compliance step is needed (`ITSAppUsesNonExemptEncryption` is set in Info.plist)
- They can check processing status at App Store Connect > TestFlight
