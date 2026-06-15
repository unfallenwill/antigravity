# Antigravity family — unofficial Linux packages (.deb / .rpm)

> ⚠️ **Unofficial.** This project is **not** affiliated with, endorsed by, or
> sponsored by **Google LLC**. **Antigravity and Antigravity IDE are (c) Google
> LLC.** The packages here contain the **unmodified official Linux binaries**
> published by Google; this project only rewraps them for convenient
> `apt`/`dnf` installation. See [NOTICE.md](NOTICE.md). If anything here should
> not be distributed this way, please open an issue.

Official product: <https://antigravity.google>

This repository packages **two distinct Google products** for Linux (x86-64 and
arm64), directly from their upstream Linux tarballs:

| Product | Package name | What it is | Channel |
|---|---|---|---|
| **Antigravity** | `antigravity` | Agentic desktop application | hub (GCS bucket, listable) |
| **Antigravity IDE** | `antigravity-ide` | VS Code–based IDE | stable (edge CDN, manual) |

They install side by side (different prefixes `/opt/antigravity` and
`/opt/antigravity-ide`, different binaries, different desktop entries).

## Install

Download the files for your distribution and architecture from
[Releases](../../releases) (each product has its own release tag, e.g.
`antigravity-v2.1.4`, `antigravity-ide-v2.0.4`), then:

```bash
# Debian / Ubuntu
sudo apt install ./antigravity_2.1.4_amd64.deb        # or _arm64.deb
sudo apt install ./antigravity-ide_2.0.4_amd64.deb     # or _arm64.deb

# Fedora / RHEL / openSUSE
sudo dnf install antigravity-2.1.4.x86_64.rpm          # or .aarch64.rpm
sudo dnf install antigravity-ide-2.0.4.x86_64.rpm      # or .aarch64.rpm
```

Launch from your application menu, or run `antigravity` / `antigravity-ide` in a
terminal. Verify downloads against the `checksums_*.txt` file in each release.

## What the packages do

- Install the app under `/opt/<product>` with a `/usr/bin/<product>` launcher,
  a `.desktop` entry, and hicolor icons.
- Set the Electron `chrome-sandbox` to `setuid root` (`chmod 4755`) on install —
  without this the app will not start on most distributions.
- Declare the standard Electron runtime dependencies so the package manager
  pulls in what it needs.
- Make **no changes** to the upstream binaries.

Updates: install a newer package; in-app auto-update is not relied upon for
system-wide installs.

## Build locally

Requirements: `curl`, `tar`, `perl`, and
[`nfpm`](https://github.com/goreleaser/nfpm)
(`go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest`).

```bash
# Antigravity (hub): version resolves from the listable GCS bucket.
PRODUCT=antigravity VERSION=2.1.4 ARCH=x64 ./packaging/build.sh

# Antigravity IDE: CHANNEL=hub auto-resolves the latest via the updater API.
PRODUCT=antigravity-ide VERSION=2.0.4 ARCH=x64 CHANNEL=hub ./packaging/build.sh
# (use CHANNEL=stable + URL_X64/URL_ARM only to pin a specific older IDE build)
```

Output lands in `dist/` (`*.deb`, `*.rpm`, `checksums_*.txt`). `ARCH` is `x64`
or `arm`.

## How new versions get packaged

There are two triggers (see [`.github/workflows/build.yml`](.github/workflows/build.yml)):

- **Manual** — `workflow_dispatch` with product + version. `CHANNEL=hub`
  auto-resolves the official source for either product, so you normally don't
  need to paste URLs. (`stable`/`custom` + explicit URLs are only for a specific
  older IDE build, since the IDE's update API exposes only the latest.)
- **Scheduled** — a cron job discovers the latest version of **both** products
  and, for any not yet released, dispatches a build run:
  - **Antigravity** — latest semver from the listable `antigravity-public` GCS
    bucket (`packaging/resolve-version.sh`).
  - **Antigravity IDE** — latest from its own auto-updater API
    (`packaging/resolve-ide.sh`). The IDE is a VS Code fork whose "Check for
    Updates" menu is wired to a hardcoded Cloud Run endpoint
    `antigravity-ide-auto-updater-…run.app/api/update/<platform>/stable/0`
    (its `product.json` `updateUrl` is a dummy `example.com` that only keeps the
    menu enabled). Passing commit `0` returns the latest release JSON,
    including the canonical download URL.

**How "is it released" is decided:** a version counts as released iff a GitHub
release tagged `<product>-v<version>` exists in this repo. Each successful build
creates that tag, so the set of tags is the source of truth — no separate state
file.

Caveats: discovery tracks the product version (semver for Antigravity, the
`x.y.z` parsed from the IDE download URL), not the build-id, so a re-release of
the same version with a new build-id is skipped automatically (re-dispatch
manually, which re-uploads with `--clobber`); and historical versions are
packaged on request, not retroactively.

## Disclaimer & license

The Antigravity binaries are proprietary to Google LLC. The packaging scripts,
templates, build tooling, and CI in this repository are MIT-licensed (see
[LICENSE](LICENSE)).

Antigravity and the Antigravity logo are trademarks of Google LLC.
