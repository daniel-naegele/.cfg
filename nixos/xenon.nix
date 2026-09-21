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
  ];

  # ---- Boot / secure boot / ZFS ----
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  # Also needed for LUKS passphrase reuse across the three disks, see the
  # comment on `disko.devices.disk` in xenon-disk-config.nix.
  boot.initrd.systemd.enable = true;
  networking.hostId = "9b940dce"; # generated via: head -c4 /dev/urandom | od -A none -t x4
  services.zfs.autoScrub.enable = true;
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
  ];

  # ---- Power (deliberately NOT the laptop's idle-hibernate policy —
  # a tower shouldn't self-suspend mid-compile/download) ----
  services.logind.settings.Login = {
    HandlePowerKey = "hibernate";
  };

  # NOTE: Nvidia's kernel module is out-of-tree and isn't automatically
  # signed by lanzaboote's tooling. After first boot with secure boot
  # enforced, verify `nvidia-smi` actually works. If the module refuses to
  # load under lockdown, consult https://wiki.nixos.org/wiki/NVIDIA and the
  # lanzaboote docs on out-of-tree module signing before reaching for
  # `open = false` or disabling lanzaboote.

  system.stateVersion = "26.05"; # fresh install, matches this flake's nixpkgs pin
}
