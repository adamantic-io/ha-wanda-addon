# Wanda Agent — Home Assistant add-on

Runs the Wanda ZTNA agent as a Home Assistant add-on so an HAOS appliance
(e.g. **Home Assistant Green**, arm64 / Rockchip RK3566) registers as a Wanda
machine reachable remotely through the bastion — no `.deb`/`.rpm`, no command
line required.

> **Status: experimental.** Tunnel-only deployment. PAM 2FA and JIT user
> provisioning are not available (container on HAOS). HTTP tunneling (HA UI) and
> raw TCP relay (SSH) work.

## Install — 3 steps

### 1. Register the machine in Wanda

Open [wanda.adamantic.net/machines](https://wanda.adamantic.net/machines), create
a new machine. Copy its **machine id** — you'll need it in step 3.

### 2. Add the add-on repository to Home Assistant

HA → Settings → Add-ons → Add-on Store → ⋮ (top-right) → **Repositories** → paste:

```
https://github.com/adamantic-io/ha-wanda-addon
```

Reload the store. **Wanda Agent** appears under *Adamantic* in the store → **Install**.

No SSH, no file copy, no on-device build. HA Supervisor pulls a pre-built image.

### 3. Configure and start

Open the **Configuration** tab of the installed add-on and set:

| Option | Description | Default |
|--------|-------------|---------|
| `bastion_address` | Bastion gRPC endpoint | `wanda.adamantic.net:8443` |
| `machine_id` | Machine id from step 1 | *(required)* |
| `tls_insecure` | Skip TLS verification (dev only) | `true` |
| `ha_target` | HA core HTTP URL | `http://localhost:8123` |
| `ssh_target` | HA SSH relay (TCP). Empty = disabled | `tcp://localhost:22` |

Click **Start**. Check the **Log** tab — should show a connection to the bastion.

Then in the Wanda web UI, bind your user to the `wanda:status` selector (HA UI)
and `remote-access` (SSH) on this machine's access profile. Open the Wanda desktop
client — the HA service appears as **HTTP / Forwardable**.

## Service types

| Service | Selector | Target | Client behaviour |
|---------|----------|--------|-----------------|
| Home Assistant UI | `wanda:status` | `http://localhost:8123` | HTTP / Forwardable — opens HA in browser |
| SSH (optional) | `remote-access` | `tcp://localhost:22` | TCP / Forwardable — connect with SSH client to the forwarded port |

SSH is a raw TCP relay (`tcp://`) to avoid Wanda's JIT user-provisioning (fails
in a container). Authentication is handled by HA's SSH add-on; Wanda's OTP gate
does not apply.

## Production TLS

`tls_insecure: true` skips certificate verification. For production, mount the
bastion CA certificate into the add-on and update `run.sh` to write
`ca_cert: /etc/wanda/ca.crt`. (Add a `map:` in `config.yaml` and extend
`run.sh` — not wired yet.)

---

## For developers

### Publish a new image

Run from the **wanda repo root** after `docker login ghcr.io`:

```bash
apps/ztna/packaging/homeassistant/wanda-agent/build-image.sh 1.0.0
```

This cross-compiles arm64 + amd64 binaries, builds a multi-arch image, and
pushes `europe-west3-docker.pkg.dev/adm-wanda/wanda-public/wanda-agent-ha:1.0.0` + `:latest`.

### Local build (no registry)

1. Build the arm64 binary:
   ```bash
   docker run --rm -v "$PWD/apps/ztna":/src -w /src \
     -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=arm64 \
     golang:1.26-alpine \
     go build -ldflags="-s -w" \
     -o /src/packaging/homeassistant/wanda-agent/wandad-arm64 ./cmd/agent
   ```
2. Comment out `image:` in `config.yaml` (Supervisor falls back to local Dockerfile).
3. Copy the folder to `/addons/wanda-agent/` on the Green and reload the store.

### Repository files

| File | Purpose |
|------|---------|
| `repository.json` | HA Supervisor repository manifest |
| `config.yaml` | Add-on manifest (`image:` points to GHCR) |
| `Dockerfile` | Used by `build-image.sh`; ignored by Supervisor when `image:` is set |
| `run.sh` | Container entrypoint — reads `/data/options.json`, writes `agent.yaml` + `services.yaml`, execs `wandad daemon` |
| `build-image.sh` | Build + push multi-arch image (run from wanda repo root) |

## Limitations

- No PAM 2FA / JIT users — HAOS won't grant a container host-user management.
- SSH is a raw TCP relay — Wanda's OTP gate does not apply on the SSH path.
- arm64 + amd64 only — other architectures need a separate binary build and
  `arch:` entry in `config.yaml`.