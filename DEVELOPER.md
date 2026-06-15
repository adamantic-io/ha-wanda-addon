# Developer notes — Wanda HA add-on

## Repository structure

| File | Purpose |
|------|---------|
| `repository.json` | HA Supervisor repository manifest |
| `config.yaml` | Add-on manifest (`image:` points to GAR) |
| `Dockerfile` | Used by `build-image.sh`; ignored by Supervisor when `image:` is set |
| `run.sh` | Container entrypoint — reads `/data/options.json`, writes `agent.yaml` + `services.yaml`, execs `wandad daemon` |
| `build-image.sh` | Build + push multi-arch image (requires access to the wanda private repo) |

## Publish a new image

Requires: access to the private wanda repo, `gcloud auth configure-docker europe-west3-docker.pkg.dev`.

```bash
gcloud auth configure-docker europe-west3-docker.pkg.dev

/path/to/ha-wanda-addon/build-image.sh 1.0.0 /path/to/wanda-repo
```

Produces and pushes:
- `europe-west3-docker.pkg.dev/adm-wanda/wanda-public/wanda-agent-ha:1.0.0`
- `europe-west3-docker.pkg.dev/adm-wanda/wanda-public/wanda-agent-ha:latest`

Multi-arch: `linux/arm64` (HA Green) + `linux/amd64`.

## Service types

| Service | Selector | Target scheme | Why |
|---------|----------|---------------|-----|
| HA web UI | `wanda:status` | `http://` | Shows as HTTP / Forwardable in client |
| SSH relay | `remote-access` | `tcp://` | Avoids JIT provisioning (fails in container); user SSHs to forwarded port |

## One-click install integration (onboarding wizard)

HA exposes deep links via `my.home-assistant.io` that redirect to the user's local
HA instance. These are the building blocks for a "click here to install" button in
the Wanda machine onboarding wizard.

### Step 1 — Add the repository (once per HA instance)

```
https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fadamantic-io%2Fha-wanda-addon
```

Opens a dialog in the user's HA to add this repo to their add-on store.

### Step 2 — Open the add-on install page

```
https://my.home-assistant.io/redirect/supervisor_addon/?addon=wanda_agent&repository_url=https%3A%2F%2Fgithub.com%2Fadamantic-io%2Fha-wanda-addon
```

Opens the Wanda Agent install page directly. If the repo is not yet added, HA adds
it automatically before opening the page. After install, the user configures
`machine_id` and `bastion_address` in the Configuration tab.

### Onboarding wizard flow (planned)

```
Wanda UI: create machine → copy machine_id
  → "Install agent on Home Assistant" button
  → Step 2 link (auto-adds repo + opens install page)
  → user sets machine_id = <pre-filled from wizard> in HA Configuration tab
  → Start
```

Pre-filling `machine_id` is not yet possible via deep link (HA doesn't support
option pre-fill in the redirect). The user must copy-paste it from the wizard.

### Prerequisite

The user's HA Supervisor must be up-to-date. Outdated Supervisor versions block
`add_repository` with: `'StoreManager.add_repository' blocked from execution,
supervisor needs to be updated first`. This is an HA maintenance issue, not a
Wanda bug — HA shows an update banner when the Supervisor is behind.

## Local build (no registry)

1. Build the arm64 binary from the wanda repo:
   ```bash
   docker run --rm -v "$PWD/apps/ztna":/src -w /src \
     -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=arm64 \
     golang:1.26-alpine \
     go build -ldflags="-s -w" -o /src/packaging/homeassistant/wanda-agent/wandad-arm64 ./cmd/agent
   ```
2. Copy `wandad-arm64` into this folder.
3. Comment out `image:` in `config.yaml` (Supervisor falls back to local Dockerfile).
4. Copy this folder to `/addons/wanda-agent/` on the Green and reload the store.
