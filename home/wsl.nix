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
    ./modules/kitty.nix
    ./modules/rclone.nix
    ./modules/gpg.nix
  ];

  home.packages = with pkgs; [
    binutils # ar and stuff
    cifs-utils
    cmake
    envoy
    ffmpeg
    file
    go
    gucharmap
    # gcc_multi # ld.bfd conflicts with binutils-wapper's
    hicolor-icon-theme
    # jetbrains-toolbox
    #jetbrains.idea-ultimate
    losslesscut-bin
    minio-client
    ninja
    nmap
    unstable.ollama
    pavucontrol
    postgresql_16
    unstable.pferd
    pmutils
    powertop
    python3
    samba
    # virtmanager # Needs virtualisation.libvirtd.enable = true; in configuration.nix and is currently deactivated
    video-trimmer
    w3m
    zip

    # Haskell/Cabal/Stack stuff
    # haskell-ci # old version, can't get it to work on unstable either
    zlib.dev
    gmp.static
    ncurses
    numactl
  ];

  accounts.email.accounts.private.primary = true;

  gtk = {
    enable = false;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Plata-Noir-Compact";
      package = pkgs.plata-theme;
    };
  };

  programs.firefox.enable = false;

  programs.ssh = {
    # enable = true;
  };

  programs.git.userEmail = "daniel@naegele.dev";

  programs.zsh.shellAliases = {
    upd = "nix flake update /home/nixos/code/nix/config/ && sudo nixos-rebuild switch --flake /home/nixos/code/nix/config/ && . ~/.zshrc";
    switch = "sudo nixos-rebuild switch --flake /home/nixos/code/nix/config";
  };

  programs.vscode = {
    enable = false;
  };

  xdg = {
    enable = false;
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

  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.file = {
    ".background-image".source = ./wallpapers/haskell.png;
  };

  services.rclone = {
    enable = true;
    # dropbox only allows 3 devices in its free plan, so we are only installing it at home
  };


  services.gnome-keyring.enable = true;
}  
