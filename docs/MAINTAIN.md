# Maintenance runbook

Every scheduled run does **one** improvement cycle. Follow this in order; do not skip the
verification step, and do not do more than one backlog item per run.

## Hard rules

1. **The interface must stay identical.** No change to layout, colour, spacing, typography, copy,
   animation timing or the interaction model. If a change would be visible, it is the wrong change.
2. **One item per run.** Take the first unchecked item in `docs/ROADMAP.md`.
3. **Verify or revert.** If you cannot demonstrate the change works, put the file back and take a
   different item. Never ship an unverified change.
4. **The two copies of the page must stay identical.** `source/index.html` and
   `android/app/src/main/assets/index.html` are the same file; the APK ships the second one. They
   have drifted before — always compare them before committing.
5. **Never commit a file you did not just write.** Fetch the live copy first, edit it, commit it,
   then read it back from GitHub and confirm the content matches. Stale local copies have silently
   reverted the manifest and the packaged page in the past.

## Steps

### 1. Toolchain

```bash
bash /scratch/work/repo/tools/bootstrap.sh     # or curl it from the repo if absent
```

Idempotent; skips anything already installed. Takes ~2 min on a cold sandbox.

### 2. Get the current source

```bash
R=https://api.github.com/repos/technicalnihilist-lgtm/iOS-music/contents
mkdir -p /scratch/work/app/assets /scratch/work/repo
curl -sL "$R/source/index.html" -H "Accept: application/vnd.github.raw" -o /scratch/work/app/assets/index.html
curl -sL "$R/android/app/src/main/AndroidManifest.xml" -H "Accept: application/vnd.github.raw" -o /scratch/work/app/AndroidManifest.xml
curl -sL "$R/android/build.sh" -H "Accept: application/vnd.github.raw" -o /scratch/work/app/build.sh
curl -sL "$R/docs/ROADMAP.md" -H "Accept: application/vnd.github.raw" -o /scratch/work/repo/docs/ROADMAP.md
curl -sL "$R/README.md" -H "Accept: application/vnd.github.raw" -o /scratch/work/repo/README.md
```

Use the API, not `raw.githubusercontent.com` — the raw CDN serves stale content for several
minutes after a commit.

### 3. Make the change

Read `docs/ROADMAP.md`, take the first unchecked item, implement exactly that. Record what you
changed and why.

### 4. Verify

```bash
# a) the page still parses and has no obvious syntax break
node --check /dev/stdin < <(sed -n '/<script>/,/<\/script>/p' /scratch/work/app/assets/index.html | sed '1d;$d')

# b) behaviour: file picking, dedupe, track switch, back chain, settings persistence
#    (recreate the harness under /scratch/work/test — see "Test harness" below)

# c) hit-testing: every control must resolve to itself via elementFromPoint, flat and tilted
```

All three must pass. If a check cannot be run, revert and choose another item.

### 5. Version

Bump `android:versionCode` by 1 and `android:versionName` patch by 0.1 in
`/scratch/work/app/AndroidManifest.xml`. Confirm with:

```bash
/scratch/work/tools/sdk/build-tools/34.0.0/aapt dump badging build/GlassPlayer.apk | head -1
```

### 6. Build

```bash
cd /scratch/work/app && bash build.sh
```

Produces `android/app/build/GlassPlayer.apk`.

**The signing key must not change.** `android/app/glassplayer.keystore` is committed to the repo for
exactly this reason — the sandbox is wiped between runs, and a freshly generated key would make the
new APK refuse to install over the previous one. Confirm the signer after every build:

```bash
$ANDROID_SDK_ROOT/build-tools/34.0.0/apksigner verify --print-certs android/app/build/GlassPlayer.apk | grep SHA-1
# must be 260ddc9a8f5553f8682c557aec6e3746ee6caf4e
```

If it differs, the keystore was not fetched — stop and fix that before releasing.

### 7. Commit

Write `source/index.html` and `android/app/src/main/assets/index.html` with **identical** content,
plus the manifest, the ticked roadmap item, a one-line changelog entry in `README.md`, and the APK.
Then **read each file back** from the API and compare hashes against the local copies.

### 8. Release

Create release `vX.Y` named `Glass Player X.Y — <short label>`, with the APK attached as
`GlassPlayer.apk` (content type `application/vnd.android.package-archive`).

### 9. Report

Three or four sentences: which item, what changed, how it was verified, new version.

## Test harness

The behavioural checks are small enough to rewrite each run. A minimal one:

- build a `File` list and dispatch `change` on `#file`; assert duplicates are rejected
- assert the title updates after a track switch, and that playlist rows are reused (node identity)
- assert `window.__onBack()` returns `true`, `true`, `false` in that order
- assert `elementFromPoint` at the centre of `#pp`, `#next`, `#prev`, `#seek`, `#closeBtn`,
  `#optBtn` returns that element or a descendant, both flat and with `--mx`/`--my` set

Run it with headless chromium and `--dump-dom`, writing results into a `data-test` attribute.

## If the date is past 2026-11-20

List the crons, pause the one named `Glass Player — 20 day improvement sprint`, and stop. The
sprint is finished.
