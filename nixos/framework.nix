# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  name,
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./framework-hardware.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ./personal-machine.nix
  ];

  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/1c4c0c60-5849-4cd2-9c2a-22008be3b7ce";
    };
  };
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  services.udev.packages = with pkgs; [
    gnome-settings-daemon
  ];

  services.desktopManager = {
    gnome.enable = true;
  };

  services.displayManager = {
    gdm.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManagers).
  services.libinput = {
    # enable = true;
    touchpad = {
      naturalScrolling = true;
      # We don't want natural scrolling on the track point or mouse
      additionalOptions = ''MatchIsTouchpad "on"'';
      # accelSpeed = "0.6";

    };
  };
  services.gnome.core-apps.enable = true;
  services.gnome.gnome-browser-connector.enable = true;

  ####################
  # POWER MANAGEMENT #
  ####################

  # GNOME integrates with ppd but we want tlp because it works better
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      USB_ALLOWLIST = "1-4 1-9"; # HDMI and USB A extension cards
      USB_EXLUDE_PHONE = 1;
      # The following tweaks are from https://www.worldofbs.com/nixos-framework/
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      START_CHARGE_THRESH_BAT0 = 90;
      STOP_CHARGE_THRESH_BAT0 = 97;
      RUNTIME_PM_ON_BAT = "auto";
    };
  };
  # Suspend-then-hibernate everywhere
  services.logind.settings.Login = {
    HandlePowerKey = "suspend-then-hibernate";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "2m";
    HandleLidSwitch = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "2h";
  };

  # libvirtd doesn't properly set up resolution and GPU acceleration
  #
  # boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Apparently there is not much sense in doing this, because it doesn't update
  # the lock file (duh)
  # system.autoUpgrade = {
  #   enable = true;
  #   flake = "/home/sgraf/code/nix/config/";
  #   allowReboot = false;
  # };
}
