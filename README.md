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
# Antigravity (hub): only the version is needed — build-id is discovered.
PRODUCT=antigravity VERSION=2.1.4 ARCH=x64 ./packaging/build.sh

# Antigravity IDE (stable): pass the upstream URLs explicitly.
PRODUCT=antigravity-ide VERSION=2.0.4 ARCH=x64 CHANNEL=stable \
  URL_X64='https://edgedl.me.gvt1.com/.../linux-x64/Antigravity%20IDE.tar.gz' \
  ./packaging/build.sh
```

Output lands in `dist/` (`*.deb`, `*.rpm`, `checksums_*.txt`). `ARCH` is `x64`
or `arm`.

## How new versions get packaged

There are two triggers (see [`.github/workflows/build.yml`](.github/workflows/build.yml)):

- **Manual** — `workflow_dispatch` with product + version (and channel / URLs
  for the stable channel).
- **Scheduled** — a cron job lists Google's public `antigravity-public` GCS
  bucket, computes the latest **Antigravity (hub)** version, and if no matching
  `antigravity-v<version>` release tag exists yet, builds and publishes it.

**How "is it released" is decided:** a version counts as released iff a GitHub
release tagged `<product>-v<version>` exists in this repo. Each successful build
creates that tag, so the set of tags is the source of truth — no separate state
file. Auto-discovery only watches the Antigravity hub channel (the only listable
source); **Antigravity IDE** (stable CDN, not listable) is packaged by manual
dispatch with explicit URLs.

Two caveats by design: discovery tracks the semver, not the build-id, so a
re-release of the same semver with a new build-id is skipped automatically
(re-dispatch manually, which re-uploads with `--clobber`); and historical
versions are packaged on request, not retroactively.

## Disclaimer & license

The Antigravity binaries are proprietary to Google LLC. The packaging scripts,
templates, build tooling, and CI in this repository are MIT-licensed (see
[LICENSE](LICENSE)).

Antigravity and the Antigravity logo are trademarks of Google LLC.
