# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Nix flake managing NixOS system configuration and home-manager user environments for multiple hosts. The primary host is `neon` (Framework 12th-gen Intel laptop) and there's also `xenon` (AMD/Nvidia tower) — both run NixOS with KDE Plasma 6.

The flake pins to `nixos-26.05` stable, with selective packages pulled from `nixos-unstable` via the `unstable` argument.

## Applying changes

```bash
# Full system rebuild (NixOS + home-manager, run on the target host)
sudo nixos-rebuild switch --flake /home/daniel/code/nix/config

# alias: switch

# Update all flake inputs and rebuild
nix flake update --flake /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/

# alias: upd

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

Two types of outputs are built:

1. **`nixosConfigurations`** — full NixOS system configs, consumed by `nixos-rebuild`. Currently: `neon`, `xenon`.
2. **`homeManagerConfigurations`** (internal) — the home-manager modules keyed by hostname, composed into NixOS configs via `home-manager.nixosModules.home-manager`.

### Directory layout

- `flake.nix` — wires everything together; defines `pkgsBySystem` with overlays, `unstableBySystem`, and the `mk*` builder functions
- `nixos/` — NixOS system-level modules
  - `personal-machine.nix` — shared config for both personal hosts: networking, fonts, printing, virtualisation, user definition
  - `framework.nix` — laptop-specific config: boot (lanzaboote secure boot + LUKS), KDE Plasma 6 (SDDM/Wayland), TLP power management
  - `framework-hardware.nix` — hardware-scan output for the Framework laptop
  - `xenon.nix` — tower-specific config: ZFS, Nvidia, KDE Plasma 6 (SDDM/Wayland), gaming
- `home/` — home-manager configurations
  - `common.nix` — shared packages and programs used across all hosts (zsh with oh-my-zsh, git, vim, tmux, fzf, direnv, broot, zoxide, etc.)
  - `private.nix` — personal hosts config (`neon`, `xenon`); imports `common.nix` plus graphical modules; defines `switch`/`upd`/`ncg` aliases
  - `modules/` — reusable home-manager modules (kitty, lazygit, zeditor, gpg, kde)
- `nixpkgs/`
  - `config.nix` — shared nixpkgs config (allowUnfree etc.)
  - `overlays/` — custom package overlays (wakatime-ls, dagger, texlive, etc.)
- `nix/nix.conf` — nix daemon settings (experimental features, substituters, etc.)
- `secrets/` — sops-nix encrypted secrets (`framework.yaml`, `github-pat.yaml`)

### Key flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-26.05 stable |
| `unstable` | nixos-unstable (accessed via `unstable` arg) |
| `home-manager` | release-26.05, follows nixpkgs |
| `nixos-hardware` | Framework 12th-gen Intel module |
| `sops-nix` | Secret management via age keys |
| `lanzaboote` | Secure boot (replaces systemd-boot) |
| `plasma-manager` | Declarative KDE Plasma config via home-manager |
| `nix-doom-emacs` | Doom Emacs HM module |

### Secrets (sops-nix)

Secrets are encrypted with age in `secrets/`. Two age keys are in `.sops.yaml`: `admin_daniel` and `machine_framework`. The WireGuard private key (`ovpn_wg_zr`) and GitHub PAT are stored here and referenced via `config.sops.secrets.<name>.path` at runtime.

### Adding a package

- System-wide (available in all users): add to `environment.systemPackages` in `nixos/framework.nix`
- User packages on personal laptop: add to `home.packages` in `home/private.nix`
- Packages needed across all hosts: add to `home/common.nix`
- For unstable packages: use `unstable.<package>` (the `unstable` arg is passed as `extraSpecialArgs`)

# RULE:
Never write too long comments. Usually the nix code is self-explanatory.
