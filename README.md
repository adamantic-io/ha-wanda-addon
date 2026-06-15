# Wanda Agent — Home Assistant add-on

Exposes your Home Assistant as a **Wanda machine**: access the HA interface
remotely through an encrypted tunnel, without opening ports or configuring a VPN.

> **Tunnel-only.** Works on Home Assistant OS (immutable appliance). PAM 2FA and
> JIT user provisioning are not available.

## Install

### 1. Register the machine in Wanda

Open [wanda.adamantic.net/machines](https://wanda.adamantic.net/machines), create
a new machine and copy its **machine id**.

### 2. Add this repository to Home Assistant

HA → Settings → Add-ons → Add-on Store → ⋮ → **Repositories** → paste:

```
https://github.com/adamantic-io/ha-wanda-addon
```

Reload the store → find **Wanda Agent** → **Install**.

### 3. Configure and start

| Option | Description | Default |
|--------|-------------|---------|
| `bastion_address` | Bastion endpoint | `wanda.adamantic.net:8443` |
| `machine_id` | Machine id from step 1 | *(required)* |
| `tls_insecure` | Skip TLS verification (dev only) | `true` |
| `ha_target` | HA web interface URL | `http://localhost:8123` |
| `ssh_target` | SSH relay (leave empty to disable) | `tcp://localhost:22` |

Click **Start**. Check the **Log** tab — should show a connection to the bastion.

## Connect from the Wanda client

In the Wanda web UI, add the `wanda:status` selector (HA interface) and
`remote-access` (SSH, if enabled) to your access profile for this machine.

Open the Wanda desktop client — the HA service appears as **HTTP / Forwardable**.

## Limitations

- No PAM 2FA or JIT user provisioning (container on HAOS).
- SSH is a raw TCP relay — Wanda's OTP gate does not apply on the SSH path;
  authentication is handled by HA's SSH add-on.
