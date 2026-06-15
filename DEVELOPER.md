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
