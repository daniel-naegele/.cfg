{ config, pkgs, lib, unstable, ... }:

let

  graphicalService = descr: pkg: exe: {
    Unit = {
      Description = "${descr}";
      Documentation = "man:${exe}(1)";
      After = "graphical-session-pre.target";
      PartOf = "graphical-session.target";
    };

    Service = {
      ExecStart = "${pkg}/bin/${exe}";
      Restart = "on-abnormal";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

in

{
  imports = [
    ./common.nix
    ./modules/dconf.nix
    ./modules/kitty.nix
    ./modules/rclone.nix
    ./modules/gpg.nix
  ];

  home.packages = with pkgs; [
    binutils # ar and stuff
    cmake
    dconf # some tools need this to preserve settings
    discord
    ethtool
    ffmpeg
    file
    gimp
    gnome.gnome-tweaks
    gnome.gnome-shell-extensions
    gnomeExtensions.bluetooth-quick-connect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.color-picker
    gnomeExtensions.system-monitor
    gnomeExtensions.impatience
    gnomeExtensions.pop-shell
    gnomeExtensions.window-calls-extended
    gnomeExtensions.vertical-overview
    google-chrome
    gpick
    gpu-screen-recorder
    gucharmap
    # gcc_multi # ld.bfd conflicts with binutils-wapper's
    hicolor-icon-theme
    # jetbrains-toolbox
    #jetbrains.idea-ultimate
    (jetbrains.plugins.addPlugins jetbrains.idea-ultimate ["nixidea"])
    jetbrains.rider
    libreoffice
    minio-client
    nextcloud-client
    ninja
    nmap
    unstable.obsidian
    obs-studio
    okular
    pavucontrol
    unstable.pferd
    pmutils
    powertop
    python3
    qbittorrent
    screen
    signal-desktop
    slack
    spotify
    texlive.combined.scheme-full
    tidal-hifi
    thunderbird
    # virtmanager # Needs virtualisation.libvirtd.enable = true; in configuration.nix and is currently deactivated
    unityhub
    vesktop
    vlc
    w3m
    xorg.xprop
    zip
    zoom-us

    # Haskell/Cabal/Stack stuff
    # haskell-ci # old version, can't get it to work on unstable either
    zlib.dev
    gmp.static
    ncurses
    numactl
  ];

  accounts.email.accounts.private.primary = true;

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Plata-Noir-Compact";
      package = pkgs.plata-theme;
    };
  };

  programs.firefox.enable = true;

  programs.ssh = {
    # enable = true;
  };

  programs.git.userEmail = "daniel@naegele.dev";

  programs.zsh.shellAliases = {
    upd = "nix flake update /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/ && . ~/.zshrc";
    switch = "sudo nixos-rebuild switch --flake /home/daniel/code/nix/config";
  };

  programs.vscode = {
    enable = true;
  };

  xdg = {
    enable = true;
    #dataFile = {
    #  "icons/hicolor/128x128/apps/spotify.png".source = "${pkgs.spotify}/share/spotify/icons/spotify-linux-128.png";
    #  "icons/hicolor/128x128/apps/code.png".source = ./vscode/icon-128.png;
    #};

#    configFile."mimeapps.list".force = true; # https://github.com/nix-community/home-manager/issues/1213
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
      };
    };
  };

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";
  home.file = {
    ".background-image".source = ./wallpapers/haskell.png;
  };

  services.rclone = {
    enable = true;
    # dropbox only allows 3 devices in its free plan, so we are only installing it at home
  };

  systemd.user.services = {
    # Touchpad gestures, accessed by the smooth gestures gnome extension
    libinput-gestures = graphicalService "libinput gestures" "${pkgs.libinput-gestures}" "libinput-gestures";
  };

  services.gnome-keyring.enable = true;

}
