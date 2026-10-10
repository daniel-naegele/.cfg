{
  config,
  pkgs,
  lib,
  unstable,
  ...
}:

{
  imports = [
    ./common.nix
    ./modules/kde.nix
    ./modules/kitty.nix
    ./modules/gpg.nix
    ./modules/zeditor.nix
    ./modules/kscreen.nix
    ./modules/wakatime.nix
  ];

  home.packages = with pkgs; [
    anki
    ausweisapp
    ausweiskopie
    bitwarden-desktop
    bitwarden-cli
    binutils # ar and stuff
    borgbackup
    cifs-utils
    unstable.claude-code
    claude-agent-acp
    cmake
    cmctl
    dagger
    dconf # some tools need this to preserve settings
    dig
    discord
    element-desktop
    esptool
    ethtool
    ffmpeg
    file
    fluffychat
    fontforge-gtk
    gcc
    gimp
    go
    golangci-lint
    google-chrome
    gopls
    gpu-screen-recorder
    gucharmap
    helm-ls
    # gcc_multi # ld.bfd conflicts with binutils-wapper's
    hicolor-icon-theme
    hujsonfmt
    img2pdf
    unstable.inkscape
    jetbrains.idea
    jetbrains.goland
    kubernetes-helm
    kube-capacity
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
    nixfmt
    nmap
    nodejs_22
    unstable.obsidian
    obs-studio
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.kate
    unstable.ollama
    papirus-icon-theme
    pavucontrol
    pdfarranger
    podman
    postgresql_16
    prismlauncher
    unstable.pferd
    pmutils
    package-version-server
    powertop
    platformio
    (python3.withPackages (python-pkgs: [
      python-pkgs.dbus-python
      python-pkgs.pygobject3
    ]))
    qbittorrent
    sabnzbd
    samba
    screen
    unstable.signal-desktop
    slack
    sops
    spotify
    teams-for-linux
    termius
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
    webex
    wireshark
    w3m
    xprop
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

  # KDE's own GTK theme sync (kded6 gtkconfig, re-applied every login from
  # the active Plasma look-and-feel) fights home-manager for ~/.gtkrc-2.0
  # and ~/.config/gtk-{3,4}.0/*, breaking `switch`'s backup step. Leaving
  # this unmanaged so KDE is the sole owner; theme/icon packages above are
  # still installed for it to use.
  gtk.enable = false;

  programs.firefox = {
    enable = true;
    # Opts into the >=26.05 XDG default early; activation script below migrates the data.
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  home.activation.migrateFirefoxConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    old="$HOME/.mozilla/firefox"
    new="${config.xdg.configHome}/mozilla/firefox"
    if [ -d "$old" ] && [ ! -e "$new" ]; then
      run mkdir -p "$(dirname "$new")"
      run mv "$old" "$new"
    fi
  '';

  programs.ssh = {
    # enable = true;
  };

  programs.git.settings.user.email = "daniel@naegele.dev";

  programs.zsh.shellAliases = {
    upd = "sudo true && nix flake update --flake /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/";
    switch = "sudo nixos-rebuild switch --flake /home/daniel/code/nix/config";
    ncg = "sudo nix-collect-garbage --delete-old #5";
    # rootful engine: rootless one gets no /dev/kvm (dagger#13827)
    dagger = "CONTAINER_HOST=unix:///run/podman/podman.sock dagger";
  };

  programs.vscode = {
    enable = true;
  };

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.kde.okular.desktop" ];
        "application/wps-office.pptx" = [ "impress.desktop" ];
        "audio/flac" = [ "vlc.desktop" ];
        "audio/mpeg" = [ "vlc.desktop" ];
        "image/png" = [ "org.kde.gwenview.desktop" ];
        "image/jpeg" = [ "org.kde.gwenview.desktop" ];
        "application/rss+xml" = [ "dev.zed.Zed.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/x-tex" = [ "dev.zed.Zed.desktop" ];
        "text/x-log" = [ "org.kde.kate.desktop" ];
        "text/xml" = [ "org.kde.kate.desktop" ];
        "video/mp4" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
        "x-scheme-handler/sgnl" = [ "signal.desktop" ];
        "x-scheme-handler/signalcaptcha" = [ "signal.desktop" ];
        "x-scheme-handler/slack" = [ "slack.desktop" ];
        "x-scheme-handler/jetbrains" = [ "jetbrainsd.desktop" ];
        "x-scheme-handler/bitwarden" = [ "bitwarden.desktop" ];
        "x-scheme-handler/termius" = [ "termius-app.desktop" ];
        "x-scheme-handler/ssh" = [ "kitty-open.desktop" ];
        "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
        "x-scheme-handler/discord" = [ "vesktop.desktop" ];
        "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
      };
    };
  };

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";
  xdg.configFile."xdg-terminals.list" = {
    text = "kitty.desktop\n";
    force = true;
  };
}
