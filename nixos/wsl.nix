# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  wsl = {
    enable = true;
    defaultUser = "nixos";
    startMenuLaunchers = true;
    nativeSystemd = true;
    useWindowsDriver = true;

    interop.register = true;
    wslConf.interop.enabled = true;
    wslConf.interop.appendWindowsPath = true;
    wslConf.network.hostname = "Daniel-PC";

    docker-desktop.enable = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  users.allowNoPasswordLogin = true;
  users.users.nixos = {
    shell = pkgs.zsh;
  };

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

  # Shoot things when there's less than 2% RAM
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
  };

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

  # Fixes Home-Manager applications not appearing in Start Menu
  system.activationScripts.copy-user-launchers = lib.stringAfter [ ] ''
    for x in applications icons; do
      echo "setting up /usr/share/''${x}..."
      targets=()
      if [[ -d "/etc/profiles/per-user/${config.wsl.defaultUser}/share/$x" ]]; then
        targets+=("/etc/profiles/per-user/${config.wsl.defaultUser}/share/$x/.")
      fi

      if (( ''${#targets[@]} != 0 )); then
        mkdir -p "/usr/share/$x"
        ${pkgs.rsync}/bin/rsync -ar --delete-after "''${targets[@]}" "/usr/share/$x"
      else
        rm -rf "/usr/share/$x"
      fi
    done
  '';

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    enableNvidia = lib.mkForce false;
  };
  users.extraGroups.docker.members = [ "nixos" ];
}
