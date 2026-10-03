# Shared NixOS configuration for Daniel's personal machines (laptop + xenon).
# Anything that's "how Daniel likes any personal Linux box configured" lives
# here; genuinely host-specific things (desktop environment, power
# management, CPU vendor, disk layout) stay in the per-host file.

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  sops = {
    defaultSopsFile = ../secrets/framework.yaml;
    secrets = {
      ovpn_wg_zr = {
        owner = "daniel";
        mode = "0600";
      };
    };
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoEnrollKeys = {
      enable = true;
      includeMicrosoftKeys = true;
      allowBrickingMyMachine = false;
      autoReboot = true;
    };
    configurationLimit = 8;
    measuredBoot = {
      enable = true;
      pcrs = [
        0
        4
        7
      ];
    };
  };
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
  };
  # Splash screen
  boot.plymouth.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.networkmanager = {
    # explicit so NetworkManager-wait-online succeeds
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
    dns = "dnsmasq";
  };

  environment.etc = {
    "NetworkManager/dnsmasq.d/dnsmasq-staging.conf".text = "address=/*.staging/127.0.0.1";
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
    keyMap = "de";
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
    inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.sbctl
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
      noto-fonts-color-emoji
      roboto
      siji
      ubuntu-classic
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        serif = [
          "Ubuntu"
          "Roboto"
        ];
        sansSerif = [
          "Ubuntu"
          "Roboto"
        ];
        monospace = [
          "Iosevka"
          "Fira Code"
          "Cascadia Code"
          "Ubuntu"
        ];
      };
    };
  };

  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [ dconf ];
  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  # Shoot things when there's less than 2% RAM
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
  };

  # Install firmware updates
  services.fwupd.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    gtk3
    glib
    nss
    nspr
    at-spi2-atk
    cups
    dbus
    libdrm
    mesa
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    pango
    cairo
    expat
    harfbuzz
  ];

  programs.zsh.enable = true;
  programs.pay-respects.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

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

  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = false;
      address = [
        "172.28.69.36/32"
        "fd00:0000:1337:cafe:1111:1111:4156:8fd4/128"
      ];
      # use dnscrypt, or proxy dns as described above
      dns = [
        "46.227.67.134"
        "192.165.9.158"
        "2a07:a880:4601:10f0:cd45::"
        "2001:67c:750:1:cafe:cd45::1"
      ];
      privateKeyFile = config.sops.secrets.ovpn_wg_zr.path;
      peers = [
        {
          publicKey = "BH/TUFM8TPoYqpry4o2ZF+rgW3DPTZHsB886Wq6aaCc=";
          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
          endpoint = "vpn43.prd.zurich.ovpn.com:9929";
        }
      ];
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  security.rtkit.enable = true; # needed for pipewire realtime scheduling

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.epson-escpr
    pkgs.gutenprint
    pkgs.gutenprintBin
    pkgs.brlaser
  ];

  programs.steam = {
    enable = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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

  # Native replacement for the GNOME GSConnect extension
  programs.kdeconnect.enable = true;

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Keyboard layout (feeds KWin/Wayland via localed).
  services.xserver = {
    xkb.layout = "de";
    xkb.options = "eurosign:e";
  };

  ####################
  # USER MANAGEMENT #
  ####################

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!"; # locked, no login
  users.users.daniel = {
    createHome = true;
    home = "/home/daniel";
    group = "users";
    description = "Daniel Nägele";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "input"
      "disk"
      "networkmanager"
      "libvirtd"
      "dialout"
      "tailscale"
      "kvm"
      "plugdev"
    ];
    uid = 1000;
    shell = pkgs.zsh;
    hashedPassword = "$6$PeNJjX6DQSKYld6x$XBooBII7i/vvyr72u6zvoa4yNN.S6dWgGh8TZcNIYS3mnVjkeGD.M0Dq30zkD8o4XP5Ual7b7P9AGa4WUb8mv1"; # mkpasswd -m sha-512
  };
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ]; # for user-mode cachix

  users.extraGroups.vboxusers.members = [ "daniel" ];
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;

      };
    };
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings = {
        dns_enabled = true;
        default_subnet = "192.168.129.0/24";
        default_subnet_pools = [
          {
            base = "192.168.130.0/24";
            size = 24;
          }
          {
            base = "192.168.131.0/24";
            size = 24;
          }
          {
            base = "192.168.132.0/24";
            size = 24;
          }
          {
            base = "192.168.133.0/24";
            size = 24;
          }
          {
            base = "192.168.134.0/24";
            size = 24;
          }
        ];
      };
    };
  };

  users.extraGroups.docker.members = [ "daniel" ];
}
