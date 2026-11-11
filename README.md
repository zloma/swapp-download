# swapp-download

Static site for the Loopa app (code name `swapp`, Android package `io.github.zloma.swapp`), served by GitHub Pages at **https://loopa.zloma.app**. No build step, no trackers, no cookies, no third-party scripts or fonts.

| Path | What |
|------|------|
| `/` (`index.html`) | Download page for the release APK (static, no script). Button links to `releases/latest/download/loopa.apk`. |
| `/i/?c=CODE` (`i/index.html`) | Invite landing page. Shows the code, "Otvori u aplikaciji" (custom scheme `io.github.zloma.swapp://invite?c=CODE`) and the download button. `noindex`. |
| `/version.json` | Latest release info, read by the app (task 4.8). |
| `/.well-known/assetlinks.json` | Android App Links verification (release + debug SHA-256). |
| `CNAME`, `.nojekyll` | Custom domain; `.nojekyll` makes Pages serve the `.well-known` folder. |

## `version.json` fields

Schema from ADR 006 (plan rows 4.7 and 4.8):

```json
{ "latest": "0.0.0", "min": "0.0.0", "url": "" }
```

| Field | Type | Meaning |
|-------|------|---------|
| `latest` | string (`x.y.z`) | Latest released version. Used by the app for the dismissible "new version" prompt. |
| `min` | string (`x.y.z`) | Lowest version still allowed to run. Older builds get the blocking update screen. `0.0.0` = no block. |
| `url` | string | Stable `https://` URL of the APK (`https://github.com/zloma/swapp-download/releases/latest/download/loopa.apk`). Only `https://` values are used. |

## Local preview

The invite page and version.json need http, so do not open the files with `file://`. Serve the folder, for example `npx serve .` or any static server, and open `http://localhost:3000/i/?c=K7M2-QX4P`.

## CSP script hash

`/i/` has a CSP meta tag that allows only an exact hash of its inline script (`/` has no script and uses `script-src 'none'`). After editing an inline `<script>`, run:

```
powershell -File tool/csp-hash.ps1          # rewrites the hashes
powershell -File tool/csp-hash.ps1 -Check   # verify only (exit 1 on mismatch)
```

A wrong hash makes the browser block the script, so the invite page would show nothing.

## GitHub Pages setup (owner steps, once)

Order matters: verify the domain **first**, so nobody else can claim `zloma.app` subdomains on GitHub Pages while the DNS record exists.

1. **Verify the domain.** GitHub profile (top right) → Settings → Pages → Add a domain → `zloma.app`. GitHub shows a TXT record (`_github-pages-challenge-zloma`). Add it at the DNS provider of `zloma.app`, click Verify, and wait until it shows as **Verified**. A verified domain cannot be claimed by another GitHub account, including after a Pages site is removed.
2. On GitHub create the **public** repo `zloma/swapp-download` (empty, no README).
3. In this folder: `git remote add origin https://github.com/zloma/swapp-download.git` then `git push -u origin main`.
4. Repo Settings → Pages → Build and deployment: Source "Deploy from a branch", Branch `main`, folder `/ (root)`.
5. Add the DNS CNAME record (below).
6. In Settings → Pages → Custom domain enter `loopa.zloma.app` and Save. (The `CNAME` file already contains it.)
7. Wait for the DNS check and certificate, then tick **Enforce HTTPS**.

### DNS record

At the DNS provider of `zloma.app`, only after step 1 shows Verified:

| Type | Name | Value |
|------|------|-------|
| CNAME | `loopa` | `zloma.github.io` |

Do not add an A record for it, and do not point it at anything else.

`.app` is on the browsers' HSTS preload list: the site only ever loads over HTTPS, so it does not open at all until GitHub has issued the certificate.

### History

Until 2026-11-10 the site was served at `loopa.zloma.org`. That domain stays verified on GitHub; its `loopa` CNAME is deleted after the switch. No invite links were distributed on the old host.

## Check App Links

After the site is live, open:

`https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://loopa.zloma.app&relation=delegate_permission/common.handle_all_urls`

The response must list `io.github.zloma.swapp` with both SHA-256 fingerprints. Also open `https://loopa.zloma.app/.well-known/assetlinks.json` directly (status 200, JSON). On an Android 12+ phone with the release APK: `adb shell pm get-app-links io.github.zloma.swapp` should show `loopa.zloma.app: verified`.

## Release signing rule

The **release SHA-256 in `assetlinks.json` must match the keystore that signs the APK** that testers install. If the keystore is ever replaced, update `assetlinks.json` in the same change, otherwise links stop opening the app (the custom-scheme button and manual entry still work). The debug fingerprint is the owner's PC only; remove it before a wider rollout if it is no longer needed. Fingerprints are public, not secrets.

Release SHA-256 `EA:D2:28:...:C3:B6`, debug SHA-256 `53:02:C5:...:FF:D7` (full values in `.well-known/assetlinks.json`, source: project brief, owner answers round 4).

## Contact

info@zloma.app

## Releasing a new version

Owner steps, in the GitHub web UI (`gh` is not installed):

1. In `index.html` change the version in the single marked spot (`<span id="version">`), and set `latest` in `version.json` to the same value. Set `min` only if older builds must be blocked. Commit and push.
2. On GitHub open the repo, Releases, "Draft a new release". Create the tag `vX.Y.Z` (for example `v0.1.1`) and publish.
3. Upload the APK with the exact asset name `loopa.apk`. Another name breaks `https://github.com/zloma/swapp-download/releases/latest/download/loopa.apk`, which the download button and `version.json` use.
4. Open the download link on a phone and check it downloads the new APK. Pages caching can delay the site by about 10 minutes.
