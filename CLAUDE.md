# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Nix flake managing NixOS system configuration and home-manager user environments for multiple hosts. The primary host is `DN-Laptop` (Framework 12th-gen Intel laptop running NixOS with GNOME), with additional home-manager-only configs for work machines (`i44pc*`) and a WSL config (`Daniel-PC`).

The flake pins to `nixos-26.05` stable, with selective packages pulled from `nixos-unstable` via the `unstable` argument.

## Applying changes

```bash
# Full system rebuild (NixOS + home-manager, run on the target host)
sudo nixos-rebuild switch --flake /home/daniel/code/nix/config

# alias: switch

# Update all flake inputs and rebuild
nix flake update --flake /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/

# alias: upd

# Home-manager only (for non-NixOS hosts)
home-manager switch --flake /home/daniel/code/nix/config/

# Garbage collect old generations
sudo nix-collect-garbage --delete-old

# alias: ncg
```

## Formatting

```bash
# Format all .nix files
treefmt

# Or directly with nixfmt
nixfmt <file>.nix
```

The formatter is `nixfmt-rfc-style` (configured in `treefmt.toml`).

## Architecture

### Entry point: `flake.nix`

Three types of outputs are built:

1. **`nixosConfigurations`** — full NixOS system configs, consumed by `nixos-rebuild`. Currently: `DN-Laptop`, `Daniel-PC`.
2. **`homeConfigurations`** — home-manager-only configs for non-NixOS hosts (`username@hostname` keys). Currently: work machines `i44pc*`.
3. **`homeManagerConfigurations`** (internal) — the home-manager modules used by both types, keyed by hostname. These are composed into NixOS configs via `home-manager.nixosModules.home-manager` or directly for standalone hosts.

### Directory layout

- `flake.nix` — wires everything together; defines `pkgsBySystem` with overlays, `unstableBySystem`, and the three `mk*` builder functions
- `nixos/` — NixOS system-level modules
  - `framework.nix` — main laptop config: boot (lanzaboote secure boot + LUKS), networking (NetworkManager + dnsmasq + WireGuard + OpenVPN KIT + Tailscale), GNOME, TLP power management, Podman/libvirtd virtualisation, user definition
  - `framework-hardware.nix` — hardware-scan output for the Framework laptop
  - `wsl.nix` — WSL-specific NixOS config
- `home/` — home-manager configurations
  - `common.nix` — shared packages and programs used across all hosts (zsh with oh-my-zsh, git, vim, tmux, fzf, direnv, broot, zoxide, etc.)
  - `private.nix` — personal laptop config; imports `common.nix` plus graphical modules; defines `switch`/`upd`/`ncg` aliases
  - `work.nix` — work machine config
  - `wsl.nix` — WSL user config
  - `modules/` — reusable home-manager modules (kakoune, kitty, lazygit, zeditor, gpg, dconf, rclone, xrandr)
- `nixpkgs/`
  - `config.nix` — shared nixpkgs config (allowUnfree etc.)
  - `overlays/` — custom package overlays (wakatime-ls, dagger, texlive, kak-*, etc.)
- `nix/nix.conf` — nix daemon settings (experimental features, substituters, etc.)
- `secrets/` — sops-nix encrypted secrets (`framework.yaml`, `github-pat.yaml`)
- `go.sh` — bootstrap script for first-time home-manager setup on a new machine

### Key flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-26.05 stable |
| `unstable` | nixos-unstable (accessed via `unstable` arg) |
| `home-manager` | release-26.05, follows nixpkgs |
| `nixos-hardware` | Framework 12th-gen Intel module |
| `sops-nix` | Secret management via age keys |
| `lanzaboote` | Secure boot (replaces systemd-boot) |
| `nixos-wsl` | WSL NixOS support |
| `nix-doom-emacs` | Doom Emacs HM module |

### Secrets (sops-nix)

Secrets are encrypted with age in `secrets/`. Two age keys are in `.sops.yaml`: `admin_daniel` and `machine_framework`. The WireGuard private key (`ovpn_wg_zr`) and GitHub PAT are stored here and referenced via `config.sops.secrets.<name>.path` at runtime.

### Adding a package

- System-wide (available in all users): add to `environment.systemPackages` in `nixos/framework.nix`
- User packages on personal laptop: add to `home.packages` in `home/private.nix`
- Packages needed across all hosts: add to `home/common.nix`
- For unstable packages: use `unstable.<package>` (the `unstable` arg is passed as `extraSpecialArgs`)
