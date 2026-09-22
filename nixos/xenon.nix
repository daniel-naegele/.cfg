{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./personal-machine.nix
    ./xenon-disk-config.nix
    ./xenon-hardware.nix
  ];

  # ---- Boot / secure boot / ZFS ----
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  # Also needed for LUKS passphrase reuse across the three disks, see the
  # comment on `disko.devices.disk` in xenon-disk-config.nix.
  boot.initrd.systemd.enable = true;
  networking.hostId = "9b940dce"; # generated via: head -c4 /dev/urandom | od -A none -t x4
  services.zfs.autoScrub.enable = true;

  # No nixos-hardware module for a custom-built desktop, so unlike the
  # laptop this needs to be requested explicitly — without it linux-firmware
  # isn't included at all and the iwlwifi card has no usable firmware.
  hardware.enableRedistributableFirmware = true;

  # Console/LUKS-prompt keyboard layout — override the laptop's "us" default.
  console.keyMap = lib.mkForce "de";
  # Desktop/KDE keyboard layout — laptop's shared "eu,de" (EurKEY primary)
  # looks like US layout for plain letters. Just use "de" outright here.
  services.xserver.xkb.layout = lib.mkForce "de";
  # Drop the laptop's caps:swapescape (Esc/CapsLock swapped) — unwanted here.
  services.xserver.xkb.options = lib.mkForce "eurosign:e";

  # Measured boot's PCR-prediction step reliably fails with "State not
  # recoverable" on this TPM after the CMOS clears + BIOS reflash we had to
  # do to recover this board (leftover stale NV state, confirmed via
  # `Esys_NV_DefineSpace`/TPM_RC_NV_DEFINED in the systemd-tpm2-setup log).
  # Tried: BIOS TPM Clear, flushing TPM contexts, re-enabling the SHA384 PCR
  # bank — none fixed it. Not load-bearing (no TPM-sealed unlock in use;
  # LUKS/ZFS FDE is unaffected) — disabling to unblock.
  boot.lanzaboote.measuredBoot.enable = lib.mkForce false;

  # Single-user desktop machine — skip the sudo password prompt.
  security.sudo.wheelNeedsPassword = false;

  # ssd870/hdd are LUKS with initrdUnlock = false (xenon-disk-config.nix) —
  # unlock them here, post-root-mount, with a keyfile that only lives on
  # zroot (so it's exactly as protected as the root passphrase). Root
  # passphrase stays the only thing typed at boot. One-time keyfile
  # generation/enrollment steps are in install.txt.
  systemd.services.unlock-storage-disks = {
    description = "Unlock ssd870/hdd LUKS containers with the zroot-resident keyfile";
    before = [
      "zfs-import-ssdpool.service"
      "zfs-import-hddpool.service"
    ];
    wantedBy = [
      "zfs-import-ssdpool.service"
      "zfs-import-hddpool.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.cryptsetup}/bin/cryptsetup open /dev/disk/by-partlabel/disk-ssd870-luks crypted-ssd870 --key-file /etc/cryptsetup-keys.d/storage.key --allow-discards
      ${pkgs.cryptsetup}/bin/cryptsetup open /dev/disk/by-partlabel/disk-hdd-luks crypted-hdd --key-file /etc/cryptsetup-keys.d/storage.key
    '';
  };
  # Do NOT set boot.kernelPackages manually — `latestCompatibleLinuxPackages`
  # is deprecated; nixpkgs's default kernel on 26.05 is already ZFS-tested.

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };
  # The LVM swap LV's `resumeDevice = true;` + `priority = -2;` (set in
  # xenon-disk-config.nix) wires boot.resumeDevice and swap priority
  # automatically — no manual boot.kernelParams resume= or swapDevices
  # entry needed here. No resume_offset needed either (that's only for a
  # swapfile-on-filesystem, which is the laptop's case, not a raw LV).

  # ---- AMD CPU (Ryzen 5800X) ----
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ---- KDE Plasma 6 (Wayland) ----
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # ---- Nvidia (RTX 3070 Ti / Ampere) ----
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam's 32-bit deps
  };
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland
    open = true; # Ampere is fully supported by open kernel modules
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  # ---- Gaming ----
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [
    lutris
    mangohud
    nvidia-vaapi-driver # HW video decode via VA-API
    nvtopPackages.nvidia
  ];

  # ---- Power (deliberately NOT the laptop's idle-hibernate policy —
  # a tower shouldn't self-suspend mid-compile/download) ----
  # Fallback for when nothing (i.e. no Plasma session) is inhibiting
  # logind's own handling. See powerdevil.AC.powerButtonAction below for
  # the setting that actually applies while Plasma is running.
  services.logind.settings.Login = {
    HandlePowerKey = "hibernate";
  };

  home-manager.users.daniel = {
    programs.plasma.kscreenlocker = {
      autoLock = true;
      lockOnResume = true;
      timeout = 10; # minutes
    };
    programs.plasma.powerdevil.AC = {
      powerButtonAction = "hibernate";
      autoSuspend = {
        action = "sleep";
        idleTimeout = 24 * 60 * 60; # 24h, in seconds
      };
      turnOffDisplay.idleTimeout = 10 * 60; # 10 minutes, in seconds
    };
  };

  # Razer BlackWidow / Naga Trinity: drivers + userspace daemon.
  # devicesOffOnScreensaver ties RGB lighting to the kscreenlocker timeout
  # above, so it goes dark at the same 10-minute mark.
  hardware.openrazer = {
    enable = true;
    users = [ "daniel" ];
    devicesOffOnScreensaver = true;
  };

  # NOTE: Nvidia's kernel module is out-of-tree and isn't automatically
  # signed by lanzaboote's tooling. After first boot with secure boot
  # enforced, verify `nvidia-smi` actually works. If the module refuses to
  # load under lockdown, consult https://wiki.nixos.org/wiki/NVIDIA and the
  # lanzaboote docs on out-of-tree module signing before reaching for
  # `open = false` or disabling lanzaboote.

  system.stateVersion = "26.05"; # fresh install, matches this flake's nixpkgs pin
}
