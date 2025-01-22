# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ name, config, pkgs, inputs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./framework-hardware.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/1c4c0c60-5849-4cd2-9c2a-22008be3b7ce";
    };
  };

  # Splash screen
  boot.plymouth.enable = true;

  networking.hostName = "DN-Laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant. Not needed when we have networkmanager.
  networking.networkmanager = {
    # although Gnome activates nm by default, it's important we activate it
    # here, too, so that NetworkManager-wait-online succeeds. But seems broken again in 22.11
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };
  # systemd.network.wait-online.anyInterface = true; # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1273814285
  systemd.services.NetworkManager-wait-online.enable = false; # https://github.com/NixOS/nixpkgs/issues/59603#issuecomment-1304869994
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.utf8";
    LC_IDENTIFICATION = "de_DE.utf8";
    LC_MEASUREMENT = "de_DE.utf8";
    LC_MONETARY = "de_DE.utf8";
    LC_NAME = "de_DE.utf8";
    LC_NUMERIC = "de_DE.utf8";
    LC_PAPER = "de_DE.utf8";
    LC_TELEPHONE = "de_DE.utf8";
    LC_TIME = "de_DE.utf8";
  };

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = "us";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    git
    htop
    openssh
    vim
    wget
    tailscale
  ];

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      cascadia-code
      fira-code
      fira-code-symbols
      font-awesome_4
      iosevka
      material-design-icons # community
      noto-fonts
      noto-fonts-emoji
      roboto
      siji
      ubuntu_font_family
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        serif = [ "Ubuntu" "Roboto" ];
        sansSerif = [ "Ubuntu" "Roboto" ];
        monospace = [ "Iosevka" "Fira Code" "Cascadia Code" "Ubuntu" ];
      };
    };
  };

  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [ dconf ];
  services.udev.packages = with pkgs; [
    gnome-settings-daemon
    yubikey-personalization
    android-udev-rules
  ];

  # Shoot things when there's less than 2% RAM
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
  };

  # Install firmware updates
  services.fwupd.enable = true;

  programs.zsh.enable = true;
  programs.thefuck.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.openvpn = {
    servers = {
      kit = {
        autoStart = false;
        updateResolvConf = true;
        config = ''
          client
          connect-retry 1
          connect-retry-max 3
          server-poll-timeout 5
          nobind
          <connection>
          remote 2a00:1398:0:4::7:6 1194 udp
          </connection>
          <connection>
          remote 141.52.226.101 1194 udp
          </connection>
          <connection>
          remote 2a00:1398:0:4::7:8 443 tcp
          </connection>
          <connection>
          remote 141.52.226.103 443 tcp
          </connection>
          dev tun
          auth-user-pass
          # use tls-ciphersuite and tls-cipher default
          # tls-version-min is needed to prevent downgrade attacks
          tls-version-min 1.3
          <ca>
          -----BEGIN CERTIFICATE-----
          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
          -----END CERTIFICATE-----
          </ca>
          verify-x509-name ovpn.scc.kit.edu name
          verb 3
        '';
      };
    };
  };


  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  security.rtkit.enable = true; # for Gnome

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.epson-escpr
    pkgs.gutenprint
    pkgs.gutenprintBin
    pkgs.brlaser
  ];

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.bluetooth.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb.layout = "eu,de";
    xkb.options = "eurosign:e, caps:swapescape";
    #dpi = 192;

    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    #displayManager.gdm.debug = true;
    desktopManager.gnome.enable = true;
    #desktopManager.gnome.debug = true;
  };

  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "daniel";
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
  services.gnome.core-utilities.enable = true;
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
      # The following tweaks are from https://www.worldofbs.com/nixos-framework/
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      START_CHARGE_THRESH_BAT0 = 90;
      STOP_CHARGE_THRESH_BAT0 = 97;
      RUNTIME_PM_ON_BAT = "auto";
    };
  };
  # Suspend-then-hibernate everywhere
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=2m
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=2h";

  ####################
  # USER MANAGEMENT #
  ####################

  users.mutableUsers = false;
  users.users.daniel = {
    createHome = true;
    home = "/home/daniel";
    group = "users";
    description = "Daniel Nägele";
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "input" "disk" "networkmanager" "libvirtd" "dialout" "tailscale"];
    uid = 1000;
    shell = pkgs.zsh;
    hashedPassword = "$6$PeNJjX6DQSKYld6x$XBooBII7i/vvyr72u6zvoa4yNN.S6dWgGh8TZcNIYS3mnVjkeGD.M0Dq30zkD8o4XP5Ual7b7P9AGa4WUb8mv1"; # mkpasswd -m sha-512
  };
  nix.settings.trusted-users = [ "root" "@wheel" ]; # for user-mode cachix

  # libvirtd doesn't properly set up resolution and GPU acceleration
  #
  # boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
  # boot.kernelModules = [ "kvm-intel" ];
  # virtualisation.kvmgt = {
  #   enable = true;
  #   vgpus = {
  #     "i915-GVTg_V5_8" = { # needs to be updated to this laptop
  #       uuid = "78afde9e-24fe-11ea-89ab-c3e54fc4e17c";
  #     };
  #   };
  # };
  # virtualisation.libvirtd.enable = true;
  #virtualisation.virtualbox.host.enable = true; # seems to be broken since Jun 23
  users.extraGroups.vboxusers.members = [ "daniel" ];
  # Unfortunately the extension pack isn't built by Hydra (unfree) and I really
  # don't want to rebuild this all the time
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      bip = "192.168.2.0/17";
      fixed-cidr = "192.168.2.1/17";
    };
  };
  users.extraGroups.docker.members = [ "daniel" ];


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
