---
name: supabase-migration
description: >
  The Firebase-to-Supabase migration runbook: the anonymous-account bridge, the
  credential-less session it produces, and the delta-sync scripts. Use this skill
  whenever the user mentions "the migration", "the bridge", "anonymous bridge",
  "claim-anonymous", "claim_migrated_data", "bridged user", "stranded user",
  "cutover", "the Firestore freeze", "delta sync", "sync.sh", "bridge_status",
  "repair_anonymous_claim", "firebase_identity_map", "sync_tombstones", "placeholder
  user", "migrated account", or asks why a user lost their journals / landed on
  CreateUserScreen with an empty home / cannot sign back in. Also use before
  testing any migration path on a device, before touching lib/anonymous_bridge.dart
  or supabase/functions/claim-anonymous/, and before deleting the bridge.
---

# Supabase Migration Runbook

> **Status: transitional.** Everything in this skill exists to be deleted at the
> Firestore freeze. Permanent Supabase behavior (schema, RLS/GRANT rules,
> timestamp conversion, auth wrappers) lives in CLAUDE.md, not here.

The data layer migrated from Firebase (Firestore + Firebase Auth) to Supabase
(Postgres + Supabase Auth). **Analytics stays on Firebase** — `firebase_core` and
`firebase_analytics` are permanent, not transitional.

**Current state: call sites swapped; the app runs on Supabase.**
`firebase_manager.dart` and `firestore_manager.dart` are deleted and
`cloud_firestore` is out of `pubspec.yaml`. All data and auth go through
`lib/supabase_auth_manager.dart` and `lib/supabase_db_manager.dart`.

**`firebase_auth` is still a dependency, and that is deliberate.** It survives
only for the anonymous-account bridge; it is not part of the data layer and should
not be reached for in new code. It gets removed at the Firestore freeze.

The Phase 7 real-device sign-in test passed, the Phase 6 quesgen dual-token build
is live on Cloud Run with `SUPABASE_URL` set, and anonymous sign-ins are enabled
on the hosted Supabase project.

## The cutover is NOT ready

An earlier version of CLAUDE.md wrongly said it was. What is verified is the
bridge's **server half** — the staged-placeholder test drove the deployed Edge
Function. Its **client half has never run successfully on a device**: does the
Firebase anonymous session survive the update, and does `AnonymousBridge.attempt()`
fire.

The first attempt (2026-07-25, an anonymous account created 2026-04-11 owning one
journal) failed — login screen, Apple sign-in, CreateUserScreen, empty home — but
**the install method invalidated the test**, so it is not evidence about the bridge
either way. The new build was pushed with `flutter run --release` over a TestFlight
install. Differing provenance makes that a *replace*, not an update, and iOS deletes
an app's keychain items on removal, taking the Firebase session with them. See
[The bridge is device-bound](#the-bridge-is-device-bound).

**Never use `flutter run` to test the migration path** — it destroys the one
credential the path depends on, and does so silently. Use TestFlight, which
preserves the container (same team `3U9565WWM2`, same bundle id
`com.isaackwok.moviejournal`). Until one anonymous account has come through a real
TestFlight update, the bridge's real-world success rate is unknown; do not force
testers onto the build before then.

Also confirmed by that investigation: the Firebase auth export contains **zero
`apple.com` identities** across all 26 users — the old app's population is 12 Google
+ 14 anonymous, and `firebase_identity_map` holds only `identity_map:google: 12`. So
`claim_migrated_data()` is *dead code in practice*: it joins `auth.identities`
against a map with no Apple rows, and the Google users it could serve are
auto-linked by email before it ever runs. It is a fallback for a case that does not
exist yet — do not rely on it as one.

**The app is TestFlight-only, which is what makes a hard cutover possible.**
Expiring the old build in App Store Connect stops it launching and forces every
tester onto the new one, collapsing the dual-write window from months to days. Two
constraints: expire only *after* the new build is available to testers, and tell
testers to **update in place rather than delete and reinstall** — deleting the app
destroys the Firebase anonymous session the bridge depends on, which is the one
failure mode that cannot be repaired afterwards.

## The anonymous-account bridge

14 pre-migration accounts were created by the old `signInAnonymously()` call (now
removed) and own **54 journals — 46% of production data**. They have no email and no
provider identity, so both normal linking paths structurally cannot find them: email
auto-linking has nothing to match on, and `claim_migrated_data()` joins on
`auth.identities`, which an anonymous user has none of.

`lib/anonymous_bridge.dart` trades the Firebase ID token still held on their device
— unforgeable proof of that uid — for the pre-created placeholder row's data, via the
`claim-anonymous` Edge Function. `hasProfileProvider` / `anonymousBridgeProvider` in
`home.dart` run it once per app start before the login screen is offered.

Two ordering rules make it correct, and both are easy to break:

- The Edge Function re-points the profile **before** deleting the placeholder auth
  user. Deleting first would cascade the profile away, and the `AFTER DELETE` trigger
  would write a `kind='user'` tombstone — which the delta-sync reads as "deleted in
  the new app" and would then refuse to re-import that user's journals for the rest
  of the window.
- `claim_anonymous_data(text, uuid)` takes the firebase_uid as an *assertion*, so
  `EXECUTE` is granted to `service_role` **only**. Granting it to `authenticated`
  would let any user re-point anyone's journals to themselves. Pinned by
  `rls_smoke.sql`.

**Verified end-to-end against the live stack on 2026-07-25**, by staging a throwaway
placeholder shaped exactly like the importer's and driving the deployed Edge Function
through it: claim succeeds, journal and profile re-point to the claimant,
`firebase_uid` survives, the placeholder auth user is deleted, **no tombstone is
written** (confirming the ordering rule above), and a second call returns
`already_claimed` without duplicating anything.

**Firebase's Anonymous provider is disabled on the project, and that is fine — do not
re-enable it.** Disabling blocks `accounts:signUp`, but *not* the `securetoken`
refresh path, so the 14 existing devices can still exchange their stored refresh
tokens for the ID token the bridge needs (tested). Re-enabling would let old builds
mint fresh anonymous accounts during the cutover window, creating new orphans. It
also means the bridge can't be re-tested via `signInAnonymously()` — mint an
anonymous-shaped token with the Admin SDK (`createUser({})` + `createCustomToken` +
`signInWithCustomToken`) instead. `claim-anonymous` checks `iss` / `aud` / RS256 /
`sub` and never reads `firebase.sign_in_provider`, so such a token exercises the
identical path.

## The credential-less session

A successful claim leaves the user holding a Supabase **anonymous** session —
`AnonymousBridge.attempt()` calls `signInAnonymously()` because a real `auth.users`
row must exist before any journal can point at it. That session has no row in
`auth.identities` and no credential, so a reinstall, a wipe, or a lost phone loses
the account for good: the Firebase anonymous session that was the only proof of
ownership goes with it, and the bridge cannot rescue the same user twice. This is the
state 46% of production data lands in.

`lib/features/account_link/` fixes it by attaching a provider identity **to the
current session**, via `SupabaseAuthManager.linkAppleIdentity()` /
`linkGoogleIdentity()`.

- **Nobody else is affected.** `signInAnonymously()` appears exactly once in `lib/`,
  inside the bridge; LoginScreen offers only Apple and Google. So
  `SupabaseAuthManager.needsIdentityLink()` returns false for every non-bridged user
  — and `needsAccountLinkProvider`, which wraps it, is false too — so none of this UI
  ever builds for them.
- **`linkIdentityWithIdToken`, never `linkIdentity()`.** The browser-OAuth variant
  shown in most Supabase docs needs an OAuth client secret this project deliberately
  never provisioned; probing it returns `"Unsupported provider: missing OAuth
  secret"`. The ID-token variant hits the same `/token?grant_type=id_token` endpoint
  as `signInWithIdToken` with `link_identity: true`, so it needs nothing new beyond
  **Allow manual linking** (Authentication → Sign In / Providers), enabled
  2026-07-25. Turning that off breaks the flow with `manual_linking_disabled`, which
  is deliberately **not** classified as a conflict — it is a project misconfiguration
  hitting everyone, and reporting it as "your Apple account is taken" would be a lie.
- **`auth.uid()` does not change**, so journals stay put and nothing needs
  re-pointing. That is the entire appeal over a sign-in-and-migrate flow.
- **It self-heals.** Linking flips `is_anonymous` server-side and gotrue emits
  `userUpdated`, which flows through the existing `authStateChanges` stream into
  `needsAccountLinkProvider` — prompt and banner disappear with no invalidation
  anywhere.
- **The conflict case is reported, not resolved.** If the chosen Apple/Google account
  already belongs to a different Supabase user, linking fails with
  `identity_already_exists`; the sheet explains it and points at the other provider. A
  merge would need a server-side journal move plus a rule for which profile survives,
  and reaching this state requires having signed up separately during the window *and*
  still holding the old Firebase session. `account_link_conflict` is logged to size
  that population before anyone builds the merge.
- **Acceptance**: `claimed_still_on_anonymous_session` in `migration/bridge_status.ts`
  trends to zero. Do not delete the bridge until it does — the bridge is what recovers
  anyone who gets stranded.

### The bridge is device-bound

`AnonymousBridge.attempt()` bails early when the device has no Firebase user or it is
not anonymous. That token is the *only* proof of ownership an anonymous account has,
so losing it — delete-and-reinstall, a wipe, a new phone — makes all three paths fail
at once:

- **email auto-link** — the placeholder's email is `syntheticEmail()`,
  `fb-<uid>@anon.migrated.invalid`, matching nothing
- **`claim_migrated_data`** — joins `auth.identities`, which an anonymous user has
  none of
- **`claim-anonymous`** — needs the token that no longer exists

The user then signs in normally, gets a fresh Supabase user, and lands on
CreateUserScreen. **Completing it is what makes the damage stick**:
`claim_migrated_data()` and `claim_anonymous_data()` both short-circuit to
`already_claimed` when the caller already has a profile, so from that point only
`repair_anonymous_claim.ts` can fix it.

This is why "update in place, never delete and reinstall" is load-bearing rather than
advisory. It was violated on the very first attempt, by someone who knew the rule —
because the violation did not look like one: `flutter run --release` over a TestFlight
install replaces the app rather than updating it (differing provenance), and iOS
deletes keychain items on removal. No prompt, no deletion, session gone. Assume the
rule will be broken again in some equally non-obvious way, and prefer detecting the
loss over documenting the rule harder.

`AnonymousBridge` only `debugPrint`s, so a release build reports nothing about which
branch it took. When diagnosing a stranded user, that absence of evidence is expected
and is not itself a clue.

### Logging out is recoverable

A bridged user cannot reach LoginScreen while holding their session — it is
constructed in exactly one place in `home.dart` and only under `if (user == null)`.
The single route there is Settings → Logout. And signing in with Apple from there
creates a *new* user rather than linking, because `signInWithIdToken` resolves an
identity to a user and ignores the current session; only `linkIdentityWithIdToken`
attaches to it.

That sounds fatal and is not, which is why the logout copy must not claim it is:

- `claim_anonymous_data`'s `already_claimed` short-circuit keys on **the caller**
  already having a profile, so it only fires on a literal retry of the same call — not
  for a freshly minted anonymous user.
- The lookup keys on `firebase_uid`, which the RPC deliberately *retains* on the
  profile row when it re-points it (`update profiles set id = …` leaves `firebase_uid`
  intact).

So the next cold start after a logout re-runs the bridge, mints anonymous user #2,
matches the profile by `firebase_uid`, moves journals and profile onto it, and returns
`'claimed'`. The Edge Function then deletes the orphaned user #1 — cascading to
nothing, and writing no tombstone, because the RPC moved its data away first. The user
lands back in their account, still unlinked, so the banner reappears.

**The genuine loss condition is unchanged and predates all of this: losing the
*Firebase* anonymous session** — reinstall, wipe, new phone.
`SupabaseAuthManager.signOut()` clears only the Supabase session, so logout does not
cause it.

## Migration scripts

All live under `migration/`. **All data and secrets live outside this repo** under
`$MIGRATION_DATA_DIR`; this is a public repo and nothing there may leak into the tree.

- **`migration/sync.sh`** — export/import/validate for the delta-sync. This is the
  normal entry point.

- **`migration/repair_anonymous_claim.ts`** — by-hand equivalent of
  `claim_anonymous_data`, for a user the bridge could not reach:
  ```bash
  node --env-file="$MIGRATION_DATA_DIR/.env" migration/repair_anonymous_claim.ts \
    --firebase-uid <uid> --to <supabase user uuid>
  ```
  **Dry run unless `--confirm`.** Refuses to write if the target has no provider
  identity (repairing onto another credential-less session rebuilds the same problem),
  if the target already owns journals (it does not merge), if the target is itself a
  pre-created migration user, if the target profile carries a `firebase_uid` (deleting
  it would write a tombstone), or if a `kind='user'` tombstone already exists for the
  uid. Moves journals + profile in one transaction, verifies against the DB rather
  than trusting row counts, then deletes the placeholder auth user **after** the commit
  — the same ordering rule as the Edge Function, and the one step with no undo.

- **`migration/bridge_status.ts`** — read-only cutover monitor, run on demand:
  ```bash
  node --env-file="$MIGRATION_DATA_DIR/.env" migration/bridge_status.ts
  ```
  Lists the anonymous cohort split into **claimed** (with the date the bridge fired)
  and **unclaimed** — the latter being the number that decides when the bridge can be
  deleted. Cohort membership is defined by a `firebase_uid` having **no row in
  `firebase_identity_map`** (anonymous Firebase accounts have no provider identity); do
  not key it off the importer's `app_metadata.anonymous` marker, which lives on the
  placeholder auth user and is deleted by a successful claim, so it can only ever see
  the unclaimed half. Exits non-zero on two real misconfigurations: a `kind='user'`
  tombstone against a still-live profile, and Firebase's Anonymous provider being
  re-enabled. Unclaimed placeholders alone are the expected mid-window state and never
  fail the run. Not wired into `sync.sh` — that runs under `set -e`, so a non-zero exit
  here would mark a successful sync as failed.

Existing Firestore timestamps are interpreted as **Asia/Taipei** on import (hardcoded
in `migration/lib/transform.ts`, deliberately not an env var).

## Deleting the bridge

When `claimed_still_on_anonymous_session` reaches zero and the Firestore freeze lands,
remove in this order:

1. `lib/anonymous_bridge.dart` and its provider wiring in `home.dart`
2. `firebase_auth` from `pubspec.yaml` (its only remaining consumer)
3. `supabase/functions/claim-anonymous/` and the `claim_anonymous_data` RPC
4. `claim_migrated_data()` and its call in `hasProfileProvider` — already dead code
5. `firebase_identity_map` / `sync_tombstones` tables and the tombstone triggers
6. `lib/features/account_link/` — only once no anonymous sessions remain

`lib/features/account_link/` is the last to go: it is what rescues anyone still
stranded, and it is inert for everyone else.
