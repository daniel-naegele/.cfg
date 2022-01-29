# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/thinkpad/x1/6th-gen>
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable NTFS Fuse FS
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos-lt"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant. Not needed when we have networkmanager.
  # networking.networkmanager = {
  #   enable = true;
  #   packages = [ pkgs.networkmanager-openvpn ];
  # };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = "de";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    git
    htop
    openssh
    vim
    wget
    gnome3.adwaita-icon-theme
    gnomeExtensions.appindicator
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.impatience
    gnomeExtensions.system-monitor
  ];

  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;

    fonts = with pkgs; [
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
  services.dbus.packages = with pkgs; [ gnome3.dconf ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  # Shoot things when there's less than 2% RAM
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
  };

  programs.zsh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.openvpn = {
    servers = {
      kit = {
        autoStart = false;
        updateResolvConf = true;
        config = ''
          client
          remote 141.52.8.19
          port 1194
          dev tap
          proto udp
          auth-user-pass
          nobind
          comp-lzo no
          tls-version-min 1.2
          ca ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          verify-x509-name "C=DE, ST=Baden-Wuerttemberg, L=Karlsruhe, O=Karlsruhe Institute of Technology, OU=Steinbuch Centre for Computing, CN=ovpn.scc.kit.edu" subject
          cipher AES-256-CBC
          auth SHA384
          reneg-sec 43200
          verb 3
          script-security 2
        '';
      };
    };
  };

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.epson-escpr
    pkgs.gutenprint
    pkgs.gutenprintBin
  ];

  # Enable sound.
  sound.enable = true;

  hardware.bluetooth.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "de,eu";
    xkbOptions = "eurosign:e, caps:swapescape";
    dpi = 132;

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        # We don't want natural scrolling on the track point or mouse
        additionalOptions = ''MatchIsTouchpad "on"'';
        accelSpeed = "0.6";
      };
    };
  };
  services.gnome.chrome-gnome-shell.enable = true;

  users.mutableUsers = false;
  users.users.sgraf = {
    createHome = true;
    home = "/home/sgraf";
    group = "users";
    description = "Sebastian Graf";
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "input" "disk" "networkmanager" "libvirtd" ];
    uid = 1000;
    shell = pkgs.zsh;
    hashedPassword = "$6$/XBcQHtEME$UA6R5al2se/3aodx8mV2XkhhMiAQ1qIBlVCgAOW5nYCtiZtmdj45Dp7DI/r.7AQQS1Op78VniNKgnKOza9TDS."; # mkpasswd -m sha-512
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5CKChZHMUIx7KYIYTgweK8oauSIdA8v2bQIPaO9ln6UwbecoryN7rvjJtV+KB46NG/2CmMBv/NEkkYz+9BU7CR0ierZUzMmvkfxqhlwXbvNpzqvngmSfY/0liHWF9H+/NaG3gY3e7kmM4Vl1MHpE4rzykFHahD9N3owOwbXXsIHXPNCPPZhJY654LLKC5YI1uQPuB8U7MXWKCd54nlL8ePBY7o+cElrOQXMdADAt60M9NH87nhiqq6t4Ytyp72b3oVrDME0bBdtsIu5aqFPqeGk+90Qqdr6Vtwren+mVdZITpH5PelCFoiRcUjuqza+qwIB5hG7IFawtWGvfgqSeB Sebastian@Sebastian-PC"
    ];
  };

  # libvirtd doesn't properly set up resolution and GPU acceleration
  #
  # boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
  # boot.kernelModules = [ "kvm-intel" ];
  # virtualisation.kvmgt = {
  #   enable = true;
  #   vgpus = {
  #     "i915-GVTg_V5_8" = {
  #       uuid = "78afde9e-24fe-11ea-89ab-c3e54fc4e17c";
  #     };
  #   };
  # };
  # virtualisation.libvirtd.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "sgraf" ];
  # Unfortunately the extension pack isn't built by Hydra (unfree) and I really
  # don't want to rebuild this all the time
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "sgraf" ];

  nix = {
    package = pkgs.nixUnstable; # flakes support
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
    trustedUsers = [ "root" "@wheel" ]; # for user-mode cachix
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.11"; # Did you read the comment?

}