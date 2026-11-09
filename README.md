# swapp-download

Static site for the Loopa app (code name `swapp`, Android package `io.github.zloma.swapp`), served by GitHub Pages at **https://loopa.zloma.org**. No build step, no trackers, no cookies, no third-party scripts or fonts.

| Path | What |
|------|------|
| `/` (`index.html`) | Download page. The button points to `apkUrl` from `version.json`. |
| `/i/?c=CODE` (`i/index.html`) | Invite landing page. Shows the code, "Otvori u aplikaciji" (custom scheme `io.github.zloma.swapp://invite?c=CODE`) and the download button. `noindex`. |
| `/version.json` | Latest release info, read by the site and by the app (task 4.8). |
| `/.well-known/assetlinks.json` | Android App Links verification (release + debug SHA-256). |
| `CNAME`, `.nojekyll` | Custom domain; `.nojekyll` makes Pages serve the `.well-known` folder. |

## `version.json` fields

```json
{ "versionName": "0.0.0", "versionCode": 0, "apkUrl": "", "minSupported": 0 }
```

| Field | Type | Meaning |
|-------|------|---------|
| `versionName` | string | Latest released version, e.g. `1.0.0`. Shown on the download page. |
| `versionCode` | integer | Android `versionCode` of the latest release. |
| `apkUrl` | string | Stable `https://` URL of the APK (planned: `https://github.com/zloma/swapp-download/releases/latest/download/<fixed-name>.apk`). Empty string = no release yet; the pages then show a placeholder. Only `https://` values are used. |
| `minSupported` | integer | Lowest `versionCode` still allowed to run. Builds below it get the blocking update screen. `0` = no block. |

Note for task 4.8: ADR 006 and plan row 4.8 describe the older shape `{latest, min, url}`. The shape above is what this site uses; align the app's version check (4.8) and `tool/release.ps1` (4.7) with it, or the ADR.

## Local preview

`fetch('/version.json')` needs http, so do not open the files with `file://`. Serve the folder, for example `npx serve .` or any static server, and open `http://localhost:3000/i/?c=K7M2-QX4P`.

## CSP script hash

Both pages have a CSP meta tag that allows only an exact hash of their inline script. After editing an inline `<script>`, run:

```
powershell -File tool/csp-hash.ps1          # rewrites the hashes
powershell -File tool/csp-hash.ps1 -Check   # verify only (exit 1 on mismatch)
```

A wrong hash makes the browser block the script, so the invite page would show nothing.

## GitHub Pages setup (owner steps, once)

1. On GitHub create the **public** repo `zloma/swapp-download` (empty, no README).
2. In this folder: `git remote add origin https://github.com/zloma/swapp-download.git` then `git push -u origin main`.
3. Repo Settings → Pages → Build and deployment: Source "Deploy from a branch", Branch `main`, folder `/ (root)`.
4. Add the DNS record (below), then in Settings → Pages → Custom domain enter `loopa.zloma.org` and Save. (The `CNAME` file already contains it.)
5. Wait for the DNS check and certificate, then tick **Enforce HTTPS**.

### DNS record

At the DNS provider of `zloma.org`:

| Type | Name | Value |
|------|------|-------|
| CNAME | `loopa` | `zloma.github.io` |

Do not add an A record for it, and do not point it at anything else.

### Verify the domain (prevents takeover)

GitHub profile (top right) → Settings → Pages → Add a domain → `zloma.org`. GitHub shows a TXT record (`_github-pages-challenge-zloma`); add it at the DNS provider and click Verify. A verified domain cannot be claimed by another GitHub account if the Pages site is ever removed.

## Check App Links

After the site is live, open:

`https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://loopa.zloma.org&relation=delegate_permission/common.handle_all_urls`

The response must list `io.github.zloma.swapp` with both SHA-256 fingerprints. Also open `https://loopa.zloma.org/.well-known/assetlinks.json` directly (status 200, JSON). On an Android 12+ phone with the release APK: `adb shell pm get-app-links io.github.zloma.swapp` should show `loopa.zloma.org: verified`.

## Release signing rule

The **release SHA-256 in `assetlinks.json` must match the keystore that signs the APK** that testers install. If the keystore is ever replaced, update `assetlinks.json` in the same change, otherwise links stop opening the app (the custom-scheme button and manual entry still work). The debug fingerprint is the owner's PC only; remove it before a wider rollout if it is no longer needed. Fingerprints are public, not secrets.

Release SHA-256 `EA:D2:28:...:C3:B6`, debug SHA-256 `53:02:C5:...:FF:D7` (full values in `.well-known/assetlinks.json`, source: project brief, owner answers round 4).

## Contact

tzlomislic@gmail.com
