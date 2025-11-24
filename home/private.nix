{
  config,
  pkgs,
  lib,
  unstable,
  ...
}:

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
    ./modules/zeditor.nix
  ];

  home.packages = with pkgs; [
    anki
    baobab
    bitwarden
    bitwarden-cli
    binutils # ar and stuff
    borgbackup
    cifs-utils
    cmake
    cmctl
    dagger
    dconf # some tools need this to preserve settings
    dig
    discord
    element-desktop
    envoy
    esptool
    ethtool
    ffmpeg
    file
    fluffychat
    fontforge-gtk
    gimp
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.bluetooth-quick-connect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.color-picker
    gnomeExtensions.impatience
    gnomeExtensions.pop-shell
    gnomeExtensions.window-calls-extended
    gnomeExtensions.gsconnect
    go
    google-chrome
    gopls
    gpick
    gpu-screen-recorder
    gucharmap
    # gcc_multi # ld.bfd conflicts with binutils-wapper's
    hicolor-icon-theme
    img2pdf
    unstable.inkscape
    # jetbrains-toolbox
    #jetbrains.idea-ultimate
    jetbrains.idea-ultimate
    jetbrains.goland
    kubernetes-helm
    libreoffice
    libtiff
    ltex-ls
    losslesscut-bin
    minio-client
    musescore
    nextcloud-client
    nil
    ninja
    nixd
    nixfmt-rfc-style
    nmap
    nodejs_22
    unstable.obsidian
    obs-studio
    kdePackages.okular
    unstable.ollama
    pavucontrol
    pdfarranger
    podman
    postgresql_16
    unstable.pferd
    pmutils
    package-version-server
    powertop

    (python3.withPackages (python-pkgs: [
      python-pkgs.dbus-python
      python-pkgs.pygobject3
    ]))
    qbittorrent
    samba
    screen
    unstable.signal-desktop
    slack
    sops
    spotify
    teams-for-linux
    texlab
    texlive.combined.scheme-full
    tidal-dl
    tidal-hifi
    thunderbird
    tor-browser
    treefmt
    # virtmanager # Needs virtualisation.libvirtd.enable = true; in configuration.nix and is currently deactivated
    umlet
    vesktop
    video-trimmer
    vlc
    vorta
    vscode-langservers-extracted
    wakatime-cli
    wakatime-ls
    whatsapp-for-linux
    wireshark
    w3m
    xorg.xprop
    yaml-language-server
    yq-go
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
    upd = "nix flake update --flake /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/ && . ~/.zshrc";
    switch = "sudo nixos-rebuild switch --flake /home/daniel/code/nix/config";
    gc = "sudo nix-collect-garbage --delete-older-than 14d";
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
        "application/wps-office.pptx" = [ "impress.desktop" ];
        "audio/flac" = [ "vlc.desktop" ];
        "audio/mpeg" = [ "vlc.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/x-tex" = [ "dev.zed.Zed.desktop" ];
        "text/x-log" = [ "org.gnome.TextEditor.desktop" ];
        "video/mp4" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
        "x-scheme-handler/sgnl" = [ " signal.desktop " ];
        "x-scheme-handler/signalcaptcha" = [ "signal.desktop" ];
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
    libinput-gestures = graphicalService "libinput gestures" "${pkgs.libinput-gestures
    }" "libinput-gestures";
  };

  services.gnome-keyring.enable = true;

}
