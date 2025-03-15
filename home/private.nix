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
    baobab
    bitwarden
    bitwarden-cli
    binutils # ar and stuff
    cifs-utils
    cmake
    dconf # some tools need this to preserve settings
    discord
    element-desktop
    envoy
    esptool
    ethtool
    ffmpeg
    file
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
    go
    google-chrome
    gpick
    gpu-screen-recorder
    gucharmap
    # gcc_multi # ld.bfd conflicts with binutils-wapper's
    hicolor-icon-theme
    unstable.inkscape
    # jetbrains-toolbox
    #jetbrains.idea-ultimate
    (jetbrains.plugins.addPlugins jetbrains.idea-ultimate ["nixidea"])
    jetbrains.goland
    libreoffice
    losslesscut-bin
    minio-client
    nextcloud-client
    nil
    ninja
    nixd
    nmap
    unstable.obsidian
    obs-studio
    okular
    unstable.ollama
    pavucontrol
    pdfarranger
    postgresql_16
    unstable.pferd
    pmutils
    powertop
    python3
    qbittorrent
    samba
    screen
    unstable.signal-desktop
    slack
    spotify
    teams-for-linux
    texlive.combined.scheme-full
    tidal-dl
    tidal-hifi
    thunderbird
    tor-browser
    # virtmanager # Needs virtualisation.libvirtd.enable = true; in configuration.nix and is currently deactivated
    umlet
    unityhub
    vesktop
    video-trimmer
    vlc
    wakatime-cli
    whatsapp-for-linux
    weave-gitops
    wireshark
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
    upd = "nix flake update --flake /home/daniel/code/nix/config/ && sudo nixos-rebuild switch --flake /home/daniel/code/nix/config/ && . ~/.zshrc";
    switch = "sudo nixos-rebuild switch --flake /home/daniel/code/nix/config";
    gc = "nix-collect-garbage --delete-older-than 14d";
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
        "audio/flac" = [ "vlc.desktop" ]; 
        "audio/mpeg" = [ "vlc.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "video/mp4" = [ "vlc.desktop" ];
      };
    };
  };

  programs.zed-editor = {
      enable = true;
      extensions = [
          "nix"
          "toml"
          "elixir"
          "make"
          "dart"
          "latex"
          "java"
          "wakatime"
      ];

      ## everything inside of these brackets are Zed options.
      userSettings = {
          assistant = {
              enabled = false;
              version = "2";
              default_open_ai_model = null;
              ### PROVIDER OPTIONS
              ### zed.dev models { claude-3-5-sonnet-latest } requires github connected
              ### anthropic models { claude-3-5-sonnet-latest claude-3-haiku-latest claude-3-opus-latest  } requires API_KEY
              ### copilot_chat models { gpt-4o gpt-4 gpt-3.5-turbo o1-preview } requires github connected
              default_model = {
                  provider = "zed.dev";
                  model = "claude-3-5-sonnet-latest";
              };
             #                inline_alternatives = [
              #                    {
              #                        provider = "copilot_chat";
              #                        model = "gpt-3.5-turbo";
              #                    }
              #                ];
          };
         hour_format = "hour24";
         auto_update = false;
         terminal = {
             alternate_scroll = "off";
             blinking = "off";
             copy_on_select = false;
             dock = "bottom";
             detect_venv = {
                 on = {
                     directories = [".env" "env" ".venv" "venv"];
                     activate_script = "default";
                 };
             };
             env = {
                 TERM = "alacritty";
             };
             font_family = "FiraCode Nerd Font";
             font_features = null;
             font_size = null;
             line_height = "comfortable";
             option_as_meta = false;
             button = false;
             shell = "system";
             #{
             #                    program = "zsh";
             #};
             toolbar = {
                 title = true;
             };
             working_directory = "current_project_directory";
        };

        lsp = {
              rust-analyzer = {
                 binary = {
                      # path = lib.getExe pkgs.rust-analyzer;
                      path_lookup = true;
                  };
              };
              nix = {
                  binary = {
                      path_lookup = true;
                  };
              };
             elixir-ls = {
                  binary = {
                      path_lookup = true;
                  };
                  settings = {
                      dialyzerEnabled = true;
                  };
              };
        };

        languages = {
            "Elixir" = {
                language_servers = ["!lexical" "elixir-ls" "!next-ls"];
                format_on_save = {
                    external = {
                        command = "mix";
                        arguments = ["format" "--stdin-filename" "{buffer_path}" "-"];
                    };
                };
            };
            "HEEX" = {
                language_servers = ["!lexical" "elixir-ls" "!next-ls"];
                format_on_save = {
                    external = {
                        command = "mix";
                        arguments = ["format" "--stdin-filename" "{buffer_path}" "-"];
                    };
                };
            };
        };

        vim_mode = false;
        ## tell zed to use direnv and direnv can use a flake.nix enviroment.
        load_direnv = "shell_hook";
        base_keymap = "JetBrains";
        theme = {
            mode = "system";
            light = "One Light";
            dark = "One Dark";
        };
        show_whitespaces = "all" ;
        ui_font_size = 24;
        buffer_font_size = 20;
        buffer_line_height = "comfortable";
        autosave = "on_focus_change";
        restore_on_startup = "last_session";
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
